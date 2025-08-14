// 📄 lib/widgets/effects/player_meteor_rain_adapter.dart
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import 'vfx_meteor_rain.dart';

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_dynamic_mover_component.dart';

/// 把“世界坐标中心 + 参数”交给 VFXMeteorRain，内部负责世界->本地坐标、定时生成流星与结算 AoE
class PlayerMeteorRainAdapter {
  final FloatingIslandPlayerComponent host;
  final Component _layer;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;
  final List<PositionComponent> Function() candidatesProvider;

  PlayerMeteorRainAdapter._({
    required this.host,
    required Component layer,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    required this.candidatesProvider,
  }) : _layer = layer;

  static PlayerMeteorRainAdapter attach({
    required FloatingIslandPlayerComponent host,
    Component? layer,
    required Vector2 Function() getLogicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey,
    required List<PositionComponent> Function() candidatesProvider,
  }) {
    final parent = layer ?? host.parent ?? host;
    return PlayerMeteorRainAdapter._(
      host: host,
      layer: parent,
      getLogicalOffset: getLogicalOffset,
      resourceBarKey: resourceBarKey,
      candidatesProvider: candidatesProvider,
    );
  }

  double _calcDamage(double atk, Gongfa? skill) {
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

  /// 读取功法等级（拿不到就按 1）
  int _levelOf(Gongfa? skill) {
    try {
      final v = (skill as dynamic).level;
      if (v is num) return v.toInt().clamp(1, 999999);
    } catch (_) {}
    return 1;
  }

  /// 释放流星坠：数量 = 功法 level（完全相等）
  Future<void> castRain({
    required Vector2 centerWorld,
    // 其余视觉参数照旧
    double spreadRadius = 140,
    double warnTime = 0.35,
    double interval = 0.08,
    double fallHeight = 420,
    double fallSpeed = 920,
    double explosionRadius = 68,
  }) async {
    // 1) 读玩家 ATK
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();

    // 2) 读已装备的攻击功法（拿 level/atkBoost）
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    // 3) 计算伤害 & 读等级
    final damage = _calcDamage(atk, skill);
    final countByLevel = _levelOf(skill); // ⭐ 数量=level

    // 4) 丢到效果层
    _layer.add(
      VfxMeteorRain(
        owner: host,
        centerWorld: centerWorld,
        count: countByLevel,                 // ← 就这个
        spreadRadius: spreadRadius,
        warnTime: warnTime,
        interval: interval,
        fallHeight: fallHeight,
        fallSpeed: fallSpeed,
        explosionRadius: explosionRadius,
        damage: damage,
        getLogicalOffset: getLogicalOffset,
        resourceBarKey: resourceBarKey,
        candidatesProvider: () => candidatesProvider()
            .whereType<FloatingIslandDynamicMoverComponent>()
            .where((c) => c.isMounted && !(c.isDead == true))
            .toList(),
        basePriority: host.priority + 60,
      ),
    );
  }
}
