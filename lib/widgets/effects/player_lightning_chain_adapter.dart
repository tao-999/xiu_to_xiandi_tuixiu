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

  // ===== 等级→条数/速度策略 =====
  int _extractLevel(Gongfa? skill) {
    try {
      final s = skill as dynamic;
      final v = (s.level ?? s.lv ?? s.stage ?? 1);
      if (v is num) return v.clamp(1, 999).toInt();
    } catch (_) {}
    return 1;
  }

  /// 链条“并行根数”= 2 + (lv-1)，封顶 12
  int _branchCountForLevel(int lv) => (2 + (lv - 1)).clamp(2, 12);

  /// 等级越高，跳速略快
  double _hopDelayForLevel(int lv) {
    final base = 0.06, minv = 0.03;
    final v = base - (lv - 1) * 0.002;
    return v < minv ? minv : v;
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

  /// 释放雷链（传候选目标；内部按等级裁最近的，且并行发射多条）
  Future<void> castChain({
    required List<FloatingIslandDynamicMoverComponent> targets,
    double? hopDelay,           // 可外部覆盖
    double thickness = 2.6,
    double jaggedness = 10,
    int segments = 18,
    Color color = const Color(0xFFB5E2FF),
  }) async {
    if (targets.isEmpty) return;

    // 1) 角色面板
    final p = await PlayerStorage.getPlayer();
    final double atk = (p != null ? PlayerStorage.getAtk(p) : 10).toDouble();
    final Gongfa? skill =
    p != null ? await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id) : null;
    final int lv = _extractLevel(skill);

    // 2) 计算并行根数 & 取最近的 N 个目标（N >= branchCount 更好看）
    final int branchCountWanted = _branchCountForLevel(lv);
    final Vector2 myPos = host.logicalPosition;
    final sorted = targets
        .where((t) => t.isMounted && !(t.isDead == true))
        .toList()
      ..sort((a, b) =>
          (a.logicalPosition - myPos).length2.compareTo((b.logicalPosition - myPos).length2));

    if (sorted.isEmpty) return;

    final int branchCount = sorted.length < branchCountWanted
        ? sorted.length
        : branchCountWanted;

    // 适当多给点目标，保证每根链能继续“跳”几次（比如每根 3~4 个目标）
    final perBranchAim = 3; // 你想更夸张就调大
    final needTotal = (branchCount * perBranchAim).clamp(branchCount, sorted.length);
    final hopTargets = sorted.take(needTotal).toList();

    // 3) 伤害 & 跳速
    final damage = _calcDamage(atk, skill);
    final delay = hopDelay ?? _hopDelayForLevel(lv);

    // 4) 上效果（并行分叉交给 VfxLightningChain 处理）
    _layer.add(
      VfxLightningChain(
        owner: host,
        startWorld: host.absoluteCenter.clone(),
        targets: hopTargets,
        branchCount: branchCount,          // ✅ 并行条数
        hopDelay: delay,
        damagePerHit: damage,
        getLogicalOffset: getLogicalOffset,
        resourceBarKey: resourceBarKey,
        thickness: thickness,
        jaggedness: jaggedness,
        segments: segments,
        color: color,
        basePriority: host.priority + 60,
      ),
    );
  }
}
