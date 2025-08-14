// 📄 lib/widgets/effects/player_laser_adapter.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' hide Image;

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/data/attack_gongfa_data.dart'; // ✅ 读模板颜色

import '../components/resource_bar.dart';
import '../components/floating_island_player_component.dart';
import '../components/floating_island_dynamic_mover_component.dart';
import 'vfx_laser_beam.dart';

/// 玩家激光适配器
/// 颜色来源优先级：实例.palette → AttackGongfaData.byName(name).palette → 红色兜底
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

  // ===== 等级解析（尽可能兼容字段名）=====
  int _extractLevel(Gongfa? skill) {
    try {
      final s = skill as dynamic;
      final dynamic v = s.level ?? s.lv ?? s.lvl ?? s.stage ?? s.grade ?? s.tier ?? 1;
      if (v is num) return v.clamp(1, 999).toInt();
    } catch (_) {}
    return 1;
  }

  // ===== 等级 → 基本参数（可按你喜好调）=====
  // 返回：(duration, width, dpsMult, maxLength)
  ({double dur, double width, double dpsMult, double maxLen}) _paramsForLevel(int lv) {
    final dur = (0.65 + 0.07 * (lv - 1)).clamp(0.65, 1.4);
    final width = (7.0 + 0.6 * (lv - 1)).clamp(7.0, 12.0);
    final dpsMult = (1.10 + 0.12 * (lv - 1)).clamp(1.10, 1.90);
    final maxLen = (360.0 + 18.0 * (lv - 1)).clamp(360.0, 560.0);
    return (dur: dur, width: width, dpsMult: dpsMult, maxLen: maxLen);
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

  /// ✅ 发射激光（支持：跟随目标、整套 palette、仅命中指定 mover）
  Future<VfxLaserBeam> cast({
    required Vector2 to,                     // 世界坐标（比如目标 absoluteCenter）
    PositionComponent? follow,               // 传目标则实时跟随
    double? overrideDuration,
    double tickInterval = 0.10,              // 每 0.1s 结算一次
    bool pierceAll = false,                  // 多束时通常 false：每束仅命中一个
    int priorityOffset = 60,
    FloatingIslandDynamicMoverComponent? onlyHit, // ✅ 只命中这个目标
  }) async {
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    final int lv = _extractLevel(skill);
    final params = _paramsForLevel(lv);
    final base = _baseDamage(atk, skill);

    // —— 把“DPS”摊成每 tick 的伤害 —— //
    final dps = base * params.dpsMult;
    final damagePerTick = dps * tickInterval;

    // === 颜色来自 data.palette（或实例 palette） ===
    final palette = _extractPalette(skill);

    final localFrom = () => _worldToLayerLocal(host.absoluteCenter);
    final localTo = follow != null
        ? () {
      final l = _layer;
      if (l is PositionComponent) return l.absoluteToLocal(follow.absoluteCenter);
      return follow.absoluteCenter;
    }
        : () => _worldToLayerLocal(to);

    final beam = VfxLaserBeam(
      getStartLocal: localFrom,
      getTargetLocal: localTo,
      maxLength: params.maxLen,
      duration: overrideDuration ?? params.dur,
      width: params.width,                 // ✅ 严格用这个宽度
      tickInterval: tickInterval,
      damagePerTick: damagePerTick,
      owner: host,
      getLogicalOffset: getLogicalOffset,
      resourceBarKey: resourceBarKey,
      pierceAll: pierceAll,
      palette: palette,                    // ✅ 整组传入
      onlyHit: onlyHit,                    // ✅ 只命中指定 mover（可 null）
      priority: (host.priority ?? 0) + priorityOffset,
    );

    _layer.add(beam);
    return beam;
  }
}
