import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import '../logic/collision/baoxiang1_collision_handler.dart';
import '../logic/collision/boss1_collision_handler.dart';
import '../logic/collision/boss2_collision_handler.dart';
import '../logic/collision/npc1_collision_handler.dart';
import '../widgets/components/floating_island_dynamic_mover_component.dart';
import '../widgets/components/floating_island_player_component.dart';
import '../widgets/components/floating_island_static_decoration_component.dart';
import '../widgets/components/resource_bar.dart';

class CollisionLogicHandler {
  // ✅ 当前已经触发过的静态组件位置集合
  static final Set<String> _staticCollisionLock = {};

  static void handleCollision({
    required FloatingIslandPlayerComponent player,
    required Vector2 logicalOffset,
    required PositionComponent other,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 新增参数
  }) {
    // ✅ 动态 NPC / 怪物
    if (other is FloatingIslandDynamicMoverComponent) {
      final double logicalDistance = (player.logicalPosition - other.logicalPosition).length;
      // if (logicalDistance > 30) return;

      switch (other.type) {
        case 'npc_1':
          Npc1CollisionHandler.handle(
            playerLogicalPosition: player.logicalPosition,
            npc: other,
            logicalOffset: logicalOffset,
          );
          break;
        case 'boss_1':
          Boss1CollisionHandler.handle(
            player: player,
            boss: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'boss_2':
          Boss2CollisionHandler.handle(
            player: player,
            boss: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        default:
          _handleMonsterCollision(player.logicalPosition, other);
      }
    }

    // ✅ 静态装饰物
    else if (other is FloatingIslandStaticDecorationComponent) {
      final double logicalDistance = (player.logicalPosition - other.worldPosition).length;
      // if (logicalDistance > 32) return;

      final key = _getComponentKey(other);
      if (_staticCollisionLock.contains(key)) return;
      _staticCollisionLock.add(key);

      switch (other.type) {
        case 'baoxiang_1':
          Baoxiang1CollisionHandler.handle(
            playerLogicalPosition: player.logicalPosition,
            chest: other,
            logicalOffset: logicalOffset,
          );
          break;
        default:
          return;
      }
    }
  }

  // ✅ 每帧调用清理“离开范围”的组件锁
  static void updateLockStatus(Vector2 playerPosition, List<FloatingIslandStaticDecorationComponent> components) {
    _staticCollisionLock.removeWhere((key) {
      FloatingIslandStaticDecorationComponent? comp;

      try {
        comp = components.firstWhere((c) => _getComponentKey(c) == key);
      } catch (_) {
        comp = null;
      }

      if (comp == null) return true;

      final dist = (playerPosition - comp.worldPosition).length;
      return dist > 32;
    });
  }

  static String _getComponentKey(FloatingIslandStaticDecorationComponent comp) {
    return '${comp.spritePath}_${comp.worldPosition.x.toInt()}_${comp.worldPosition.y.toInt()}';
  }

  static void _handleMonsterCollision(Vector2 playerPosition, FloatingIslandDynamicMoverComponent monster) {
    final delta = playerPosition - monster.logicalPosition;
    final rebound = delta.length > 0.01
        ? delta.normalized()
        : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

    monster.logicalPosition -= rebound * 10;
    monster.pickNewTarget();
  }
}
