import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';

import 'floating_island_dynamic_spawner_component.dart';

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
    _pickNewTarget();
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
      _pickNewTarget();
      return;
    }

    dir.normalize();
    final nextPos = logicalPosition + dir * speed * dt;

    // 🌟 先检测下一帧位置地形
    final nextTerrain = spawner.getTerrainType(nextPos);

    if (!spawner.allowedTerrains.contains(nextTerrain)) {
      // 🚀 如果即将越界，不移动，换目标
      _pickNewTarget();
      return;
    }

    // 🚀 只有合法才更新逻辑坐标
    logicalPosition = nextPos;

    // 🚀 可选: Clamp到物理边界
    final minX = movementBounds.left + size.x / 2;
    final maxX = movementBounds.right - size.x / 2;
    final minY = movementBounds.top + size.y / 2;
    final maxY = movementBounds.bottom - size.y / 2;

    logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
    logicalPosition.y = logicalPosition.y.clamp(minY, maxY);
  }

  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  void _pickNewTarget() {
    final rand = Random();
    targetPosition = Vector2(
      movementBounds.left + rand.nextDouble() * movementBounds.width,
      movementBounds.top + rand.nextDouble() * movementBounds.height,
    );
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
    } else if (collisionCooldown <= 0) {
      _pickNewTarget();
      collisionCooldown = 0.5;
    }
    super.onCollision(points, other);
  }
}
