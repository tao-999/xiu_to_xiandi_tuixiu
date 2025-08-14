// 📄 lib/widgets/combat/player_fireball_adapter.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' hide Image;

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/vfx_fireball.dart';

class PlayerFireballAdapter {
  final FloatingIslandPlayerComponent host;
  final Component _layer;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  PlayerFireballAdapter._({
    required this.host,
    required Component layer,
    required this.getLogicalOffset,
    required this.resourceBarKey,
  }) : _layer = layer;

  static PlayerFireballAdapter attach({
    required FloatingIslandPlayerComponent host,
    Component? layer,
    required Vector2 Function() getLogicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    final parent = layer ?? host.parent ?? host;
    return PlayerFireballAdapter._(
      host: host,
      layer: parent,
      getLogicalOffset: getLogicalOffset,
      resourceBarKey: resourceBarKey,
    );
  }

  Vector2 _worldToLayerLocal(Vector2 world) {
    final l = _layer;
    if (l is PositionComponent) return l.absoluteToLocal(world);
    return world;
  }

  // ===== 等级解析（尽可能兼容字段名）=====
  int _extractLevel(Gongfa? skill) {
    try {
      final s = skill as dynamic;
      final dynamic v =
          s.level ?? s.lv ?? s.lvl ?? s.stage ?? s.grade ?? s.tier ?? 1;
      if (v is num) return v.clamp(1, 999).toInt();
    } catch (_) {}
    return 1;
  }

  // ===== 等级→并发数（更激进）=====
  int _countForLevel(int lv) {
    if (lv <= 1) return 1;
    if (lv == 2) return 2;
    if (lv == 3) return 3;
    if (lv == 4) return 4;
    if (lv <= 6) return 5;
    return 6; // 上限 6 发
  }

  // ===== 并发→扇形总角度（别太窄，不重叠）=====
  double _spreadDegForCount(int n) {
    switch (n) {
      case 1: return 0;
      case 2: return 28;  // 两发就 28°
      case 3: return 36;
      case 4: return 42;
      case 5: return 48;
      default: return 54; // 6 发
    }
  }

  // —— 伤害 = ATK × (1 + atkBoost) —— //
  double _calcFireballDamage(double atk, Gongfa? skill) {
    double boost = 0.0;
    if (skill != null) {
      try {
        final v = (skill as dynamic).atkBoost;
        if (v is num) boost = v.toDouble();
      } catch (_) {}
    }
    final dmg = atk * (1.0 + boost);
    return dmg.clamp(1.0, 1e9);
  }

  // 为每一发挑“不同路线” + 左右对称
  ({FireballRoute route, double amp, double freq, double phase}) _routeForShot(int i, int n) {
    // 幅度随并发数稍增，确保前段就分开；最大 ~90px
    final baseAmp = (40.0 + (n - 1) * 10.0).clamp(40.0, 90.0);
    final baseFreq = 1.3 + 0.25 * (i % 5);
    final basePhase = (i * math.pi / 3.0);

    // 相对中心的索引（负=左，正=右）
    final center = (n - 1) / 2.0;
    final rel = i - center;
    final left = rel <= 0;

    // 交替分配：左右恒弯 + 正弦 + 抖动，保证明显分叉
    final FireballRoute route = switch (i % 3) {
      0 => (left ? FireballRoute.arcLeft : FireballRoute.arcRight),
      1 => FireballRoute.sine,
      _ => FireballRoute.wobble,
    };

    // 给一点相位差，避免后期又同步
    final phase = basePhase + rel * 0.7;

    // 频率微扰
    final freq = baseFreq;

    // 左右两侧幅度一样即可，方向由路线/扇形角控制
    final amp = baseAmp;

    return (route: route, amp: amp, freq: freq, phase: phase);
  }

  /// 发射火球（支持并行多发 + 不同路线）
  Future<void> cast({
    required Vector2 to,                     // 世界坐标（比如 target.absoluteCenter）
    PositionComponent? follow,               // 追踪目标（可选）
    double speed = 420.0,
    double radius = 10.0,
    double trailFreq = 45.0,
    double lifeAfterHit = 0.20,
    int priorityOffset = 50,
    double turnRateDegPerSec = 0,            // 0=直飞；>0=追踪
    double? maxDistance,                     // 攻击范围（像素）
    bool explodeOnTimeout = true,            // 超程是否小爆散（无伤害）
  }) async {
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    final int lv = _extractLevel(skill);
    final int shotCount = _countForLevel(lv);

    final damage = _calcFireballDamage(atk, skill);

    final worldFrom = host.absoluteCenter.clone();
    final localFrom = _worldToLayerLocal(worldFrom);
    final localTo   = _worldToLayerLocal(to);

    final totalSpreadDeg = _spreadDegForCount(shotCount);

    // 调试看看到底发了几发
    // （看日志里有：shots=2 才对；如果是 1，说明你的功法没读到 level）
    // ignore: avoid_print
    print('[Fireball] level=$lv shots=$shotCount spread=${totalSpreadDeg}°');

    for (int i = 0; i < shotCount; i++) {
      final double offsetDeg = (shotCount == 1)
          ? 0.0
          : (-totalSpreadDeg / 2.0) + (totalSpreadDeg) * (i / (shotCount - 1));

      final r = _routeForShot(i, shotCount);

      _layer.add(
        FireballVfx(
          from: localFrom,
          to: localTo,
          speed: speed,
          radius: radius,
          trailFreq: trailFreq,
          lifeAfterHit: lifeAfterHit,
          follow: follow,
          turnRateDegPerSec: turnRateDegPerSec,
          damage: damage,
          owner: host,
          getLogicalOffset: getLogicalOffset,
          resourceBarKey: resourceBarKey,
          maxDistance: maxDistance ?? 460.0,
          explodeOnTimeout: explodeOnTimeout,
          priority: (host.priority ?? 0) + priorityOffset + i,

          // 扇形起飞角（加大）
          initialAngleOffsetDeg: offsetDeg,

          // 路线参数
          route: r.route,
          routeAmpPx: r.amp,
          routeFreqHz: r.freq,
          routePhase: r.phase,
          routeDecay: 0.85, // 近目标更容易收束命中；想更野就调低
        ),
      );
    }
  }
}
