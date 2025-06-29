import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class FloatingIslandDynamicMoverComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  /// 速度
  double speed;

  /// 逻辑坐标
  Vector2 logicalPosition;

  /// 运动边界
  final Rect movementBounds;

  /// 当前目标
  Vector2 targetPosition;

  /// 碰撞冷却
  double collisionCooldown = 0.0;

  FloatingIslandDynamicMoverComponent({
    required Sprite sprite,
    required Vector2 position,
    Vector2? size,
    this.speed = 30,
    required this.movementBounds,
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()
      ..collisionType = CollisionType.active);
    _pickNewTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 碰撞冷却递减
    if (collisionCooldown > 0) {
      collisionCooldown -= dt;
    }

    // 移动到目标点
    final dir = targetPosition - logicalPosition;
    if (dir.length < 5) {
      _pickNewTarget();
    } else {
      dir.normalize();
      logicalPosition += dir * speed * dt;
    }

    // 边界限制
    logicalPosition.x = logicalPosition.x.clamp(
      movementBounds.left + size.x / 2,
      movementBounds.right - size.x / 2,
    );
    logicalPosition.y = logicalPosition.y.clamp(
      movementBounds.top + size.y / 2,
      movementBounds.bottom - size.y / 2,
    );
  }

  /// 更新显示坐标
  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  /// 随机新目标
  void _pickNewTarget() {
    final rand = Random();
    targetPosition = Vector2(
      movementBounds.left +
          rand.nextDouble() * movementBounds.width,
      movementBounds.top +
          rand.nextDouble() * movementBounds.height,
    );
  }

  /// 碰到东西时换目标
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (collisionCooldown <= 0) {
      _pickNewTarget();
      collisionCooldown = 0.5; // 防止一直抖
    }
    super.onCollision(intersectionPoints, other);
  }
}
