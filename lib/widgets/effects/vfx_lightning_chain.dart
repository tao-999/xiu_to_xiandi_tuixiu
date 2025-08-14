import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/vfx_electro_hit_overlay.dart';

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';
import 'vfx_lightning_bolt.dart';
import 'vfx_lightning_hit_flash.dart';

/// 雷链总控：支持“并行分叉”
/// - branchCount 条链从玩家同时劈出
/// - 传入的 targets 会按 round-robin 分到各分支：
///   分支0: t0, tN, t2N...
///   分支1: t1, tN+1...
class VfxLightningChain extends Component with HasGameReference {
  final FloatingIslandPlayerComponent owner;

  /// 世界起点（玩家中心）
  final Vector2 startWorld;

  /// 所有候选目标（我会按分支拆分）
  final List<FloatingIslandDynamicMoverComponent> targets;

  final int branchCount;             // ✅ 并行根数
  final double damagePerHit;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  // VFX
  final double hopDelay;
  final double thickness;
  final double jaggedness;
  final int segments;
  final Color color;

  final int? basePriority;

  // 运行态
  double _t = 0;

  late final List<List<FloatingIslandDynamicMoverComponent>> _branches;
  late final List<int> _emittedPerBranch; // 每条链已放出的段数

  VfxLightningChain({
    required this.owner,
    required this.startWorld,
    required this.targets,
    required this.damagePerHit,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    this.branchCount = 1,
    this.hopDelay = 0.04,
    this.thickness = 2.6,
    this.jaggedness = 10,
    this.segments = 18,
    this.color = const Color(0xFFB5E2FF),
    this.basePriority,
  });

  // ===== 坐标系工具（与火球一致） =====
  PositionComponent? get _layerPC =>
      parent is PositionComponent ? parent as PositionComponent : null;

  /// 世界 -> 父层本地
  Vector2 _toLocal(Vector2 world) {
    final lp = _layerPC;
    return lp != null ? lp.absoluteToLocal(world) : world;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (basePriority != null) priority = basePriority!;

    final b = branchCount <= 0 ? 1 : branchCount;
    final effBranches = targets.isEmpty ? 1 : (targets.length < b ? targets.length : b);

    // 按 round-robin 划分分支
    _branches = List.generate(effBranches, (_) => <FloatingIslandDynamicMoverComponent>[]);
    for (int i = 0; i < targets.length; i++) {
      _branches[i % effBranches].add(targets[i]);
    }
    _emittedPerBranch = List<int>.filled(effBranches, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    int finished = 0;
    int maxLen = 0;

    for (int bi = 0; bi < _branches.length; bi++) {
      final branch = _branches[bi];
      maxLen = branch.length > maxLen ? branch.length : maxLen;

      int emitted = _emittedPerBranch[bi];
      if (emitted >= branch.length) {
        finished++;
        continue;
      }

      // 该分支按自己的已发段数推进；与其他分支并行
      while (emitted < branch.length && _t >= (emitted + 1) * hopDelay) {
        final fromW = (emitted == 0)
            ? startWorld
            : branch[emitted - 1].absoluteCenter.clone();
        final tgt = branch[emitted];
        final endW = (tgt.isMounted ? tgt.absoluteCenter.clone() : fromW);

        // 坐标转父层本地
        final fromL = _toLocal(fromW);
        final endL  = _toLocal(endW);

        // 画电弧 & 命中光效（分支做个优先级微偏移，避免视觉盖住）
        final baseP = (priority) + 1 + bi * 2;
        parent?.addAll([
          VfxLightningBolt(
            startWorld: fromL,
            endWorld: endL,
            thickness: thickness,
            jaggedness: jaggedness,
            segments: segments,
            color: color,
            basePriority: baseP,
          ),
          VfxLightningHitFlash(
            worldPos: endL,
            basePriority: baseP + 1,
          ),
        ]);

        // 结算伤害
        if (tgt.isMounted && !(tgt.isDead == true)) {
          tgt.applyDamage(
            amount: damagePerHit,
            killer: owner,
            logicalOffset: getLogicalOffset(),
            resourceBarKey: resourceBarKey,
          );
          // 命中覆盖层（挂到目标下，自动跟随）
          tgt.add(
            VfxElectroHitOverlay(
              life: 0.18,
              arcCount: 9,
              arcSegments: 7,
              jitter: 9,
              thickness: 1.6,
              color: const Color(0xFFB5F3FF),
              pulse: 0.75,
              shake: 0.9,
              basePriority: 100000,
            ),
          );
        }

        emitted++;
      }

      _emittedPerBranch[bi] = emitted;
      if (emitted >= branch.length) finished++;
    }

    // 全分支结束后，稍等把控制器移除
    if (finished == _branches.length && _t >= (maxLen * hopDelay + 0.15)) {
      removeFromParent();
    }
  }
}
