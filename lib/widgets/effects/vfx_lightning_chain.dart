import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';
import 'vfx_lightning_bolt.dart';
import 'vfx_lightning_hit_flash.dart';

/// 雷链总控：按顺序在段与段之间打电弧，并在每跳命中时结算伤害
/// ✅ 修复：坐标统一转换为“父层本地坐标”（参考火球术做法）
class VfxLightningChain extends Component with HasGameReference {
  final FloatingIslandPlayerComponent owner;

  /// 世界坐标（起点 = 玩家中心，外部传 world）
  final Vector2 startWorld;

  /// 目标组件（用于结算 & 取世界坐标）
  final List<FloatingIslandDynamicMoverComponent> targets;

  final double damagePerHit;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  // VFX
  final double hopDelay;
  final double thickness;
  final double jaggedness;
  final int segments;
  final Color color;

  // ✅ 避免与 Component.priority 冲突
  final int? basePriority;

  double _t = 0;
  int _emitted = 0; // 已经放出的段数（也是已命中的目标数量）

  VfxLightningChain({
    required this.owner,
    required this.startWorld,
    required this.targets,
    required this.damagePerHit,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    this.hopDelay = 0.04,
    this.thickness = 2.6,
    this.jaggedness = 10,
    this.segments = 18,
    this.color = const Color(0xFFB5E2FF),
    this.basePriority,
  });

  // ===== 坐标系工具（对齐火球术） =====
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    // 逐跳释放
    while (_emitted < targets.length && _t >= (_emitted + 1) * hopDelay) {
      // —— 取世界坐标 —— //
      final fromW = _emitted == 0
          ? startWorld
          : targets[_emitted - 1].absoluteCenter.clone();

      final tgt = targets[_emitted];
      final endW = (tgt.isMounted ? tgt.absoluteCenter.clone() : fromW);

      // —— 统一转本地坐标（关键修复点） —— //
      final fromL = _toLocal(fromW);
      final endL  = _toLocal(endW);

      // —— 画电弧 & 闪光（本地坐标） —— //
      parent?.addAll([
        VfxLightningBolt(
          startWorld: fromL,   // 这里传入的已是“父层本地”
          endWorld: endL,
          thickness: thickness,
          jaggedness: jaggedness,
          segments: segments,
          color: color,
          basePriority: (priority) + 1,
        ),
        VfxLightningHitFlash(
          worldPos: endL,      // 同上：本地坐标
          basePriority: (priority) + 2,
        ),
      ]);

      // —— 结算伤害（目标仍用组件引用） —— //
      if (tgt.isMounted && !(tgt.isDead == true)) {
        tgt.applyDamage(
          amount: damagePerHit,
          killer: owner,
          logicalOffset: getLogicalOffset(),
          resourceBarKey: resourceBarKey,
        );
      }

      _emitted += 1;
    }

    // 全部释放完并且多等一会儿就移除自己
    if (_emitted >= targets.length && _t >= (targets.length * hopDelay + 0.15)) {
      removeFromParent();
    }
  }
}
