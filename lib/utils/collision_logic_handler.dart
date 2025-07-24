import 'package:flame/components.dart';
import '../logic/collision/npc1_collision_handler.dart';
import '../widgets/components/floating_island_dynamic_mover_component.dart';

class CollisionLogicHandler {
  static void handleCollision({
    required Vector2 playerPosition,
    required Vector2 logicalOffset, // ✅ 新增相机偏移参数
    required PositionComponent other,
  }) {
    if (other is FloatingIslandDynamicMoverComponent) {
      final double logicalDistance = (playerPosition - other.logicalPosition).length;

      // ✅ 防止远距离误触发
      if (logicalDistance > 64) return;

      switch (other.type) {
        case 'npc_1':
          print('💥 玩家碰撞到了：${other.runtimeType}'
              '${other is FloatingIslandDynamicMoverComponent ? ' | type=${other.type} ~ label=${other.labelText}, pos=${other.logicalPosition} playerPos=${playerPosition}' : ''}');
          Npc1CollisionHandler.handle(
            playerLogicalPosition: playerPosition,
            npc: other,
            logicalOffset: logicalOffset, // ✅ 关键传入！
          );
          break;

        default:
          _handleMonsterCollision(playerPosition, other);
      }
    }
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
