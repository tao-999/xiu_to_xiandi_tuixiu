import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';

import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_player_component.dart';

class FloatingIslandDynamicMoverComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  /// 逻辑坐标
  Vector2 logicalPosition;

  /// 当前目标
  Vector2 targetPosition;

  /// 运动边界
  final Rect movementBounds;

  /// 移动速度
  double speed;

  /// 碰撞冷却
  double collisionCooldown = 0.0;

  /// 贴图路径
  final String? spritePath;

  /// 所属spawner
  final FloatingIslandDynamicSpawnerComponent spawner;

  /// 自定义碰撞
  void Function(Set<Vector2> points, PositionComponent other)? onCustomCollision;

  FloatingIslandDynamicMoverComponent({
    required this.spawner,
    required Sprite sprite,
    required Vector2 position,
    Vector2? size,
    this.speed = 30,
    required this.movementBounds,
    this.spritePath,
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.active);
    pickNewTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (collisionCooldown > 0) {
      collisionCooldown -= dt;
    }

    final dir = targetPosition - logicalPosition;
    final distance = dir.length;

    if (distance < 2) {
      pickNewTarget();
      return;
    }

    dir.normalize();
    final nextPos = logicalPosition + dir * speed * dt;

    // 🌟 检测下一帧位置的地形
    final nextTerrain = spawner.getTerrainType(nextPos);

    if (!spawner.allowedTerrains.contains(nextTerrain)) {
      // 🚀 即将越界，换目标
      pickNewTarget();
      return;
    }

    // 🚀 合法则更新逻辑坐标
    logicalPosition = nextPos;

    // 🚀 Clamp到边界
    final minX = movementBounds.left + size.x / 2;
    final maxX = movementBounds.right - size.x / 2;
    final minY = movementBounds.top + size.y / 2;
    final maxY = movementBounds.bottom - size.y / 2;

    if (minX >= maxX || minY >= maxY) {
      // 🚀 边界太小，重置到中心
      logicalPosition = movementBounds.center.toVector2();
    } else {
      logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
      logicalPosition.y = logicalPosition.y.clamp(minY, maxY);
    }
  }

  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  void pickNewTarget() {
    final rand = Random();
    targetPosition = Vector2(
      movementBounds.left + rand.nextDouble() * movementBounds.width,
      movementBounds.top + rand.nextDouble() * movementBounds.height,
    );
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (onCustomCollision != null) {
      // 如果外部有自定义碰撞回调
      onCustomCollision!(points, other);
    } else if (collisionCooldown <= 0) {
      if (other is FloatingIslandPlayerComponent) {
        // 🚀 和角色碰撞：双方弹开
        final delta = logicalPosition - other.logicalPosition;
        final rebound = delta.length > 0.01
            ? delta.normalized()
            : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

        logicalPosition += rebound * 10; // 自己弹开
        other.logicalPosition -= rebound * 5; // 角色也弹开

        // 换目标
        pickNewTarget();
        collisionCooldown = 0.5;
      } else {
        // 🚀 和其他漂浮物或物体碰撞：只自己换目标
        pickNewTarget();
        collisionCooldown = 0.5;
      }
    }

    super.onCollision(points, other);
  }
}
