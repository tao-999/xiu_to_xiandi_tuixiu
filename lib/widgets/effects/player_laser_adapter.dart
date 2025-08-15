import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' hide Image;

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/data/attack_gongfa_data.dart'; // 读取模板颜色

import '../components/resource_bar.dart';
import '../components/floating_island_player_component.dart';
import '../components/floating_island_dynamic_mover_component.dart';
import 'vfx_laser_bullet.dart'; // ✅ 用子弹而不是 beam

/// 玩家激光适配器（子弹式激光）
class PlayerLaserAdapter {
  final FloatingIslandPlayerComponent host;
  final Component _layer;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  PlayerLaserAdapter._({
    required this.host,
    required Component layer,
    required this.getLogicalOffset,
    required this.resourceBarKey,
  }) : _layer = layer;

  static PlayerLaserAdapter attach({
    required FloatingIslandPlayerComponent host,
    Component? layer,
    required Vector2 Function() getLogicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    final parent = layer ?? host.parent ?? host;
    return PlayerLaserAdapter._(
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

  // ===== 等级解析 =====
  int _extractLevel(Gongfa? skill) {
    try {
      final s = skill as dynamic;
      final dynamic v = s.level ?? s.lv ?? s.lvl ?? s.stage ?? s.grade ?? s.tier ?? 1;
      if (v is num) return v.clamp(1, 999).toInt();
    } catch (_) {}
    return 1;
  }

  // ===== 等级 → 参数 =====
  // 返回：(width, maxLen, bulletSpeed, tailLen)
  ({double width, double maxLen, double speed, double tail}) _paramsForLevel(int lv) {
    final width = (5.0 + 0.4 * (lv - 1)).clamp(4.5, 6.5);     // 更细，不再是棍
    final maxLen = (360.0 + 18.0 * (lv - 1)).clamp(360.0, 560.0); // 射程不变
    final speed = (1200.0 + 60.0 * (lv - 1)).clamp(1200.0, 1600.0); // 飞得更快
    final tail  = (24.0 + 2.0 * (lv - 1)).clamp(22.0, 36.0);       // 尾迹更短
    return (width: width, maxLen: maxLen, speed: speed, tail: tail);
  }

  // —— 基础伤害 = ATK × (1 + atkBoost) —— //
  double _baseDamage(double atk, Gongfa? skill) {
    double boost = 0.0;
    if (skill != null) {
      try {
        final v = (skill as dynamic).atkBoost;
        if (v is num) boost = v.toDouble();
      } catch (_) {}
    }
    final dmg = atk * (1.0 + boost);
    return dmg.clamp(1.0, 1e12);
  }

  // ===== 从功法 / 数据模板提取 palette（支持 List<Color/int/String>）=====
  List<Color> _extractPalette(Gongfa? skill) {
    // 1) 实例自带
    try {
      if (skill != null) {
        final dyn = skill as dynamic;
        final pal = dyn.palette;
        if (pal is List) {
          final res = <Color>[];
          for (final e in pal) {
            final c = _toColor(e);
            if (c != null) res.add(c);
          }
          if (res.isNotEmpty) return res;
        }
      }
    } catch (_) {}

    // 2) 模板 byName
    try {
      final name = (skill as dynamic?)?.name as String?;
      if (name != null) {
        final tpl = AttackGongfaData.byName(name);
        if (tpl != null && tpl.palette.isNotEmpty) {
          return List<Color>.from(tpl.palette);
        }
      }
    } catch (_) {}

    // 3) 兜底：高能红
    return const [
      Color(0xFFFFFFFF), // 白核
      Color(0xFFFFE082), // 淡金
      Color(0xFFFF7043), // 橙红
      Color(0xFFFF1744), // 鲜红
      Color(0xFFD50000), // 深红
    ];
  }

  Color? _toColor(dynamic v) {
    if (v is Color) return v;
    if (v is int) {
      final hasAlpha = (v >> 24) != 0;
      return hasAlpha ? Color(v) : Color(0xFF000000 | v);
    }
    if (v is String) {
      var s = v.trim().toLowerCase();
      if (s.startsWith('0x')) {
        final val = int.tryParse(s.substring(2), radix: 16);
        if (val == null) return null;
        final hasAlpha = s.length == 10;
        return hasAlpha ? Color(val) : Color(0xFF000000 | val);
      }
      if (s.startsWith('#')) {
        s = s.substring(1);
        if (s.length == 6) {
          final val = int.tryParse(s, radix: 16);
          if (val == null) return null;
          return Color(0xFF000000 | val);
        } else if (s.length == 8) {
          final val = int.tryParse(s, radix: 16);
          if (val == null) return null;
          return Color(val);
        }
      }
    }
    return null;
  }

  /// ✅ 发射“子弹式激光”——有速度飞行、只命中一个（与火球同款整伤），颜色来自 data.palette
  Future<VfxLaserBullet> cast({
    required Vector2 to,                     // 世界坐标（比如目标 absoluteCenter）
    PositionComponent? follow,               // 若传，则用其当前位置定向（不跟踪）
    double? overrideDuration,                // 子弹不需要，用不到（兼容参数）
    double tickInterval = 0.10,              // 兼容参数
    bool pierceAll = false,                  // 子弹版默认 false：只命中一个
    int priorityOffset = 60,
    FloatingIslandDynamicMoverComponent? onlyHit, // ✅ 只命中该目标
  }) async {
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    final int lv = _extractLevel(skill);
    final params = _paramsForLevel(lv);
    final base = _baseDamage(atk, skill);       // ✅ 与火球一致的基础伤害（一次性）

    final palette = _extractPalette(skill);

    // —— 出膛点、瞄准点（一次性取，不跟随） —— //
    final startLocal = _worldToLayerLocal(host.absoluteCenter);
    final targetLocal = follow != null
        ? () {
      final l = _layer;
      if (l is PositionComponent) return l.absoluteToLocal(follow.absoluteCenter);
      return follow.absoluteCenter;
    }()
        : _worldToLayerLocal(to);

    Vector2 dir = targetLocal - startLocal;
    final len = dir.length;
    if (len < 1e-5) dir = Vector2(1, 0); else dir /= len;

    final bullet = VfxLaserBullet(
      startLocal: startLocal,
      dirUnit: dir,
      speed: params.speed,
      maxDistance: params.maxLen,
      tailLength: params.tail,
      width: params.width,
      palette: palette,
      onceDamage: base,                       // ✅ 单次整伤
      owner: host,
      getLogicalOffset: getLogicalOffset,
      resourceBarKey: resourceBarKey,
      onlyHit: onlyHit,                       // ✅ 每束只打一个
      priority: (host.priority ?? 0) + priorityOffset,
    );

    _layer.add(bullet);
    return bullet;
  }
}
