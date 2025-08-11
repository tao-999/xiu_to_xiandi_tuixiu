// 📄 lib/widgets/combat/player_fireball_adapter.dart
import 'dart:async';

import 'package:flame/components.dart';                 // Vector2 / Component / PositionComponent
import 'package:flutter/widgets.dart';                  // GlobalKey
import 'package:flutter/material.dart' hide Image;      // 颜色等（可选）

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/effects/vfx_fireball.dart';

/// 负责把“世界坐标 → 渲染层本地坐标”，并把伤害/上下文传给 VFX
class PlayerFireballAdapter {
  final FloatingIslandPlayerComponent host;
  final Component _layer;                                  // 渲染层（默认 host.parent）
  final Vector2 Function() getLogicalOffset;              // 地图逻辑偏移
  final GlobalKey<ResourceBarState> resourceBarKey;       // 刷 UI

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

  // —— 伤害 = ATK × (1 + atkBoost) —— //
  double _calcFireballDamage(double atk, Gongfa? skill) {
    double boost = 0.0; // 0~1
    if (skill != null) {
      try {
        final v = (skill as dynamic).atkBoost;
        if (v is num) boost = v.toDouble();
      } catch (_) {}
    }
    final dmg = atk * (1.0 + boost);
    return dmg.clamp(1.0, 1e9);
  }

  /// 发射火球
  /// - follow 不为空即可微追踪（turnRateDegPerSec 控最大转角）
  /// - maxDistance = 攻击范围（飞到尽头就爆散，不造成伤害）
  Future<void> cast({
    required Vector2 to,                     // 世界坐标（比如 target.absoluteCenter）
    PositionComponent? follow,               // 追踪目标（可选）
    double speed = 420.0,
    double radius = 10.0,
    double trailFreq = 45.0,
    double lifeAfterHit = 0.20,
    int priorityOffset = 50,
    double turnRateDegPerSec = 0,            // 0=直飞；>0=追踪
    double? maxDistance,                     // 🆕 攻击范围 = 最大飞行距离（像素）
    bool explodeOnTimeout = true,            // 🆕 超程是否小爆散（无伤害）
  }) async {
    // 1) 读玩家 ATK
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();

    // 2) 读已装备的攻击功法，拿 atkBoost
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    // 3) 计算一次性伤害
    final damage = _calcFireballDamage(atk, skill);

    // 4) 世界 → 父层本地
    final worldFrom = host.absoluteCenter.clone();
    final localFrom = _worldToLayerLocal(worldFrom);
    final localTo   = _worldToLayerLocal(to);

    // 5) 丢 VFX（命中里会直接 other.applyDamage(...)）
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
        damage: damage,                                // ★ 伤害=ATK*(1+atkBoost)
        owner: host,
        getLogicalOffset: getLogicalOffset,
        resourceBarKey: resourceBarKey,
        maxDistance: maxDistance ?? 360.0,             // ★ 攻击范围 = 最大飞行距离
        explodeOnTimeout: explodeOnTimeout,
        priority: (host.priority ?? 0) + priorityOffset,
      ),
    );
  }
}
