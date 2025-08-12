// 📄 lib/widgets/effects/vfx_meteor_rain.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_player_component.dart';
import '../components/floating_island_dynamic_mover_component.dart';
import '../components/resource_bar.dart';

import 'vfx_meteor_telegraph.dart';
import 'vfx_meteor_boulder.dart';     // 使用 impactLocal（避免与 PositionComponent.toLocal() 冲突）
import 'vfx_meteor_explosion.dart';

/// 管理“多枚流星”生成、坐标转换、命中 AoE 结算
/// - 入参落点用【世界坐标】，内部统一转为父层本地坐标（对齐火球）
class VfxMeteorRain extends Component with HasGameReference {
  final FloatingIslandPlayerComponent owner;

  // —— 入参（世界/视觉参数） —— //
  final Vector2 centerWorld;             // 目标中心（世界）
  final int count;                       // 数量
  final double spreadRadius;             // 随机散布半径（世界）
  final double warnTime;                 // 落点预告时间（秒）——0 或以下：完全不画圈
  final double interval;                 // 连续生成间隔（秒）
  final double fallHeight;               // 视觉起始高度（本地坐标系 y-方向）
  final double fallSpeed;                // 下落速度（px/s，本地）
  final double explosionRadius;          // AoE 半径（世界）

  // —— 结算 —— //
  final double damage;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;
  final List<FloatingIslandDynamicMoverComponent> Function() candidatesProvider;

  // —— 层级 —— //
  final int? basePriority;

  // —— 内部状态 —— //
  late final Random _rng;
  double _t = 0.0;
  int _emitted = 0;

  VfxMeteorRain({
    required this.owner,
    required this.centerWorld,
    required this.count,
    required this.spreadRadius,
    required this.warnTime,
    required this.interval,
    required this.fallHeight,
    required this.fallSpeed,
    required this.explosionRadius,
    required this.damage,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    required this.candidatesProvider,
    this.basePriority,
  }) {
    _rng = Random();
  }

  // ===== 坐标系（对齐火球术） =====
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

    // 按 interval 逐个生成
    while (_emitted < count && _t >= _emitted * interval) {
      // 1) 随机一个落点（世界，均匀圆盘）
      final ang = _rng.nextDouble() * pi * 2;
      final r = sqrt(_rng.nextDouble()) * spreadRadius;
      final offset = Vector2(cos(ang), sin(ang))..scale(r);
      final dropW = centerWorld + offset;   // 世界坐标（用于伤害）
      final dropL = _toLocal(dropW);        // 本地坐标（用于渲染）

      // 2) 只有 warnTime > 0 才画预告圈
      if (warnTime > 0) {
        parent?.add(
          VfxMeteorTelegraph(
            centerLocal: dropL,
            warnTime: warnTime,
            basePriority: priority + 1,
          ),
        );
      }

      // 3) 下落时序：无预告则立刻落；有预告则略提前 0.03s 命中
      final fallTime = fallHeight / fallSpeed;
      final impactDelay = warnTime > 0 ? max(0.0, warnTime - 0.03) : 0.0;
      final startDelay = impactDelay - fallTime;
      final delayStart = startDelay > 0 ? startDelay : 0.0;

      // 4) 下落流星体（到点触发 onImpact）
      parent?.add(
        VfxMeteorBoulder(
          fromLocal: dropL - Vector2(0, fallHeight),
          impactLocal: dropL,
          fallTime: fallTime,
          basePriority: priority + 2,
          delayStart: delayStart,
          onImpact: () {
            // a) 冲击波视觉（本地）
            parent?.add(
              VfxMeteorExplosion(
                centerLocal: dropL,
                radius: explosionRadius,
                basePriority: priority + 3,
              ),
            );

            // b) AoE 伤害结算（世界）
            final victims = candidatesProvider();
            final r2 = explosionRadius * explosionRadius;
            for (final m in victims) {
              final d2 = m.absoluteCenter.distanceToSquared(dropW);
              if (d2 <= r2) {
                m.applyDamage(
                  amount: damage,
                  killer: owner,
                  logicalOffset: getLogicalOffset(),
                  resourceBarKey: resourceBarKey,
                );
              }
            }
          },
        ),
      );

      _emitted += 1;
    }

    // 全部完成后一小段时间移除自己
    final tailWait = 0.30;
    final totalWindow =
        (_emitted == 0 ? 0.0 : (_emitted - 1) * interval) + (warnTime > 0 ? warnTime : 0.0) + tailWait;
    if (_emitted >= count && _t >= totalWindow) {
      removeFromParent();
    }
  }
}
