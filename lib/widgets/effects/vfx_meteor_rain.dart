// 📄 lib/widgets/effects/vfx_meteor_rain.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_player_component.dart';
import '../components/floating_island_dynamic_mover_component.dart';
import '../components/resource_bar.dart';

import 'vfx_meteor_boulder.dart';
import 'vfx_meteor_telegraph.dart';

class VfxMeteorRain extends Component with HasGameReference {
  final FloatingIslandPlayerComponent owner;

  /// 施法时玩家的世界坐标（固定为攻击半径的圆心）
  final Vector2 centerWorld;

  // —— 配置 —— //
  final int count;
  final double spreadRadius;     // 以 centerWorld 为圆心
  final double warnTime;         // s
  final double interval;         // s
  final double fallHeight;       // grid 本地 px
  final double fallSpeed;        // grid 本地 px/s
  final double explosionRadius;  // 世界 px（伤害 AoE）

  // —— 结算 —— //
  final double damage;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;
  final List<FloatingIslandDynamicMoverComponent> Function() candidatesProvider;

  final bool Function(FloatingIslandDynamicMoverComponent m)? isBossPredicate;
  final int? basePriority;

  // 调试
  static const bool kDbg = true;
  void _log(String s) { if (kDbg) debugPrint('[Meteor] $s'); }

  // 运行态
  final Random _rng = Random();
  double _t = 0.0;
  int _emitted = 0;

  late final Vector2 _originW;                 // 固定圆心（施法瞬间）
  late final PositionComponent _grid;          // ✅ 所有特效只加到这个 grid
  final Set<int> _usedTargetIds = <int>{};     // 本次施放已锁定的目标

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
    this.isBossPredicate,
    this.basePriority,
  });

  // ===== 工具 =====
  Vector2 _mWorld(FloatingIslandDynamicMoverComponent m) => m.absoluteCenter.clone();

  bool _mountedAlive(FloatingIslandDynamicMoverComponent m) {
    try {
      final d = m as dynamic;
      if (d.isMounted is bool && d.isMounted == false) return false;
      if (d.isDead    is bool && d.isDead    == true ) return false;
    } catch (_) {}
    return true;
  }

  bool _isBoss(FloatingIslandDynamicMoverComponent m) {
    if (isBossPredicate != null) return isBossPredicate!(m);
    try {
      final d = m as dynamic;
      if ((d.isBoss is bool) && d.isBoss == true) return true;
      final s = ('${d.type}|${d.name}|${d.category}|${d.rank}|${d.tags}').toLowerCase();
      return s.contains('boss') || s.contains('首领') || s.contains('领主');
    } catch (_) {}
    return m.runtimeType.toString().toLowerCase().contains('boss');
  }

  FloatingIslandDynamicMoverComponent _closestTo(
      Vector2 centerW, List<FloatingIslandDynamicMoverComponent> list) {
    list.sort((a, b) {
      final da = _mWorld(a).distanceToSquared(centerW);
      final db = _mWorld(b).distanceToSquared(centerW);
      return da.compareTo(db);
    });
    return list.first;
  }

  /// 只在“固定圆心 _originW 的半径内”挑一个目标：
  /// 终点(世界)=目标.absoluteCenter；渲染层=grid（统一）
  _Pick _pickImpact() {
    final r2 = spreadRadius * spreadRadius;
    final all = candidatesProvider().where(_mountedAlive).toList();
    final inside = all.where((m) =>
    _mWorld(m).distanceToSquared(_originW) <= r2 &&
        !_usedTargetIds.contains(identityHashCode(m))
    ).toList();

    if (inside.isNotEmpty) {
      final bosses = inside.where(_isBoss).toList();
      final target = bosses.isNotEmpty ? _closestTo(_originW, bosses)
          : _closestTo(_originW, inside);
      _usedTargetIds.add(identityHashCode(target));
      final world = _mWorld(target);        // ✅ 世界终点（快照）
      final local = _grid.absoluteToLocal(world); // ✅ grid 本地终点
      return _Pick(world: world, local: local, note: 'target:${target.runtimeType}');
    }

    // 没目标 → 随机半径内（仍加到 grid）
    final ang = _rng.nextDouble() * pi * 2;
    final r   = sqrt(_rng.nextDouble()) * spreadRadius;
    final world = _originW + Vector2(cos(ang), sin(ang)) * r;
    final local = _grid.absoluteToLocal(world);
    return _Pick(world: world, local: local, note: 'random');
  }

  // 层级
  static const int _P_TELE =  99980;
  static const int _P_ROCK =  99990;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (basePriority != null) priority = basePriority!;
    _originW = centerWorld.clone(); // 🔒 固定圆心

    // ✅ 锁死 grid：mover 挂在 grid 里，所以 owner.parent 就是 grid
    if (owner.parent is! PositionComponent) {
      throw StateError('VfxMeteorRain requires owner.parent as PositionComponent (grid).');
    }
    _grid = owner.parent as PositionComponent;

    _log('cast: originW=$_originW, R=$spreadRadius, grid=${_grid.hashCode}');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    while (_emitted < count && _t >= _emitted * interval) {
      final fallTime   = fallHeight / fallSpeed;
      final impactLead = (warnTime > 0 ? (warnTime - 0.03) : 0.0).clamp(0.0, 10.0);
      final delayStart = (impactLead - fallTime).clamp(0.0, 10.0);

      // === 终点只认 mover.center / absoluteCenter（两点式），渲染层=grid ===
      final pick = _pickImpact();

      // 每颗流星快照（闭包不串）
      final _Shot shot = _Shot(
        impactW: pick.world.clone(),   // 世界
        impactL: pick.local.clone(),   // grid 本地
        aoeR:    explosionRadius,
        note:    pick.note,
      );

      final dist = shot.impactW.distanceTo(_originW);
      _log('spawn: ${shot.note}, impactW=${shot.impactW}, impactL=${shot.impactL}, '
          'distToOrigin=$dist (R=$spreadRadius), grid=${_grid.hashCode}');

      // 预警圈（可选）
      if (warnTime > 0) {
        _grid.add(VfxMeteorTelegraph(
          centerLocal: shot.impactL,
          warnTime: warnTime,
          basePriority: _P_TELE,
        ));
      }

      // —— 落体：全都加到 grid；坐标是 grid 本地 —— //
      _grid.add(
        VfxMeteorBoulder(
          fromLocal: shot.impactL - Vector2(0, fallHeight),
          impactLocal: shot.impactL,
          fallTime: fallTime,
          delayStart: delayStart,
          basePriority: _P_ROCK,
          onImpact: () {
            // ✅ 判定：世界系、同一份 impactW；只对 AoE 内扣血
            final victims = candidatesProvider();
            final double r2 = shot.aoeR * shot.aoeR;
            int hits = 0;

            for (final m in victims) {
              if (!_mountedAlive(m)) continue;
              final d2 = _mWorld(m).distanceToSquared(shot.impactW);
              if (d2 > r2) continue;
              hits++;
              m.applyDamage(
                amount: damage,
                killer: owner,
                logicalOffset: getLogicalOffset(),
                resourceBarKey: resourceBarKey,
              );
            }

            _log('impact: ${shot.note}, impactW=${shot.impactW}, hits=$hits, AoE=${shot.aoeR}, grid=${_grid.hashCode}');
          },
          headRadius: 20,
        ),
      );

      _emitted += 1;
    }

    // 收尾
    const tailWait = 0.30;
    final totalWindow =
        (_emitted == 0 ? 0.0 : (_emitted - 1) * interval) + (warnTime > 0 ? warnTime : 0.0) + tailWait;
    if (_emitted >= count && _t >= totalWindow) {
      removeFromParent();
    }
  }
}

// 选点结果：世界 + grid 本地
class _Pick {
  final Vector2 world;
  final Vector2 local;
  final String note;
  _Pick({required this.world, required this.local, required this.note});
}

// 每颗流星快照
class _Shot {
  final Vector2 impactW;   // 世界
  final Vector2 impactL;   // grid 本地
  final double aoeR;
  final String note;
  _Shot({required this.impactW, required this.impactL, required this.aoeR, required this.note});
}
