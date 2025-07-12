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

  /// 默认是否朝右
  final bool defaultFacingRight;

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
    required this.defaultFacingRight,
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
      pickNewTarget();
      return;
    }

    logicalPosition = nextPos;

    // Clamp到边界
    final minX = movementBounds.left + size.x / 2;
    final maxX = movementBounds.right - size.x / 2;
    final minY = movementBounds.top + size.y / 2;
    final maxY = movementBounds.bottom - size.y / 2;

    if (minX >= maxX || minY >= maxY) {
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

    final minDistance = 500.0;
    final maxDistance = 800.0;

    // 🌟 随机一个方向向量
    Vector2 dir;
    do {
      dir = Vector2(
        rand.nextDouble() * 2 - 1, // [-1,1]
        rand.nextDouble() * 2 - 1, // [-1,1]
      );
    } while (dir.length < 0.1); // 避免接近零向量

    dir.normalize();

    final distance = minDistance + rand.nextDouble() * (maxDistance - minDistance);
    final offset = dir * distance;

    targetPosition = logicalPosition + offset;

    final movingRight = targetPosition.x > logicalPosition.x;
    final sameDirection =
        (defaultFacingRight && movingRight) || (!defaultFacingRight && !movingRight);

    scale.x = sameDirection ? 1 : -1;
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
    } else if (collisionCooldown <= 0) {
      if (other is FloatingIslandPlayerComponent) {
        final delta = logicalPosition - other.logicalPosition;
        final rebound = delta.length > 0.01
            ? delta.normalized()
            : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

        logicalPosition += rebound * 10;
        other.logicalPosition -= rebound * 5;

        pickNewTarget();
        collisionCooldown = 0.5;
      } else {
        pickNewTarget();
        collisionCooldown = 0.5;
      }
    }

    super.onCollision(points, other);
  }
}
