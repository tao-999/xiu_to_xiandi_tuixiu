import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/resource_bar.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_dynamic_mover_component.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/effects/vfx_lightning_chain.dart';

/// 把“世界坐标/目标组件 → 渲染 & 结算”，对齐火球适配器的职责
class PlayerLightningChainAdapter {
  final FloatingIslandPlayerComponent host;
  final Component _layer;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  PlayerLightningChainAdapter._({
    required this.host,
    required Component layer,
    required this.getLogicalOffset,
    required this.resourceBarKey,
  }) : _layer = layer;

  static PlayerLightningChainAdapter attach({
    required FloatingIslandPlayerComponent host,
    Component? layer,
    required Vector2 Function() getLogicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    final parent = layer ?? host.parent ?? host;
    return PlayerLightningChainAdapter._(
      host: host,
      layer: parent,
      getLogicalOffset: getLogicalOffset,
      resourceBarKey: resourceBarKey,
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

  /// 释放雷链（传入已经选好的目标序列）
  Future<void> castChain({
    required List<FloatingIslandDynamicMoverComponent> targets,
    double hopDelay = 0.04,
    double thickness = 2.6,
    double jaggedness = 10,
    int segments = 18,
    Color color = const Color(0xFFB5E2FF),
  }) async {
    if (targets.isEmpty) return;

    // 1) 读玩家 ATK
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();

    // 2) 读已装备的攻击功法，拿 atkBoost
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;

    // 3) 计算一次性伤害（每跳同伤）
    final damage = _calcDamage(atk, skill);

    // 4) 丢到效果层（由 VFX 逐跳结算伤害）
    _layer.add(
      VfxLightningChain(
        owner: host,
        startWorld: host.absoluteCenter.clone(),
        targets: targets,
        hopDelay: hopDelay,
        damagePerHit: damage,
        getLogicalOffset: getLogicalOffset,
        resourceBarKey: resourceBarKey,
        thickness: thickness,
        jaggedness: jaggedness,
        segments: segments,
        color: color,
        basePriority: host.priority + 60, // ✅ 不与 Component.priority 冲突
      ),
    );
  }
}
