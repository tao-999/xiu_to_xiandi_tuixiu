import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'floating_island_dynamic_spawner_component.dart';

class FloatingIslandDynamicMoverComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  Vector2 logicalPosition;
  Vector2 targetPosition;
  final Rect movementBounds;
  double speed;
  double collisionCooldown = 0.0;
  double tauntCooldown = 0.0;

  final String? spritePath;
  final dynamic spawner;
  final double dynamicTileSize;
  final bool defaultFacingRight;
  final double minDistance;
  final double maxDistance;

  final String? type;
  final String? labelText;
  final double? labelFontSize;
  final Color? labelColor;

  void Function(Set<Vector2> points, PositionComponent other)? onCustomCollision;
  TextComponent? label;

  bool isMoveLocked = false;
  Vector2? _externalTarget;

  // 🛡️ 新增：攻击、防御、血量属性（默认值）
  double? hp;
  double? atk;
  double? def;

  FloatingIslandDynamicMoverComponent({
    required this.dynamicTileSize,
    this.type,
    this.spawner,
    required Sprite sprite,
    required Vector2 position,
    Vector2? size,
    this.speed = 30,
    required this.movementBounds,
    this.spritePath,
    required this.defaultFacingRight,
    this.minDistance = 500.0,
    this.maxDistance = 2000.0,
    this.labelText,
    this.labelFontSize,
    this.labelColor,
    this.hp = 100,
    this.atk = 10,
    this.def = 5,
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);

    if (labelText != null && labelText!.isNotEmpty) {
      label = TextComponent(
        text: labelText!,
        anchor: Anchor.bottomCenter,
        position: position - Vector2(0, size.y / 2 + 4),
        priority: 998,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: labelFontSize ?? 12,
            color: labelColor ?? Colors.white,
          ),
        ),
      );
      parent?.add(label!);
    }

    pickNewTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (collisionCooldown > 0) collisionCooldown -= dt;
    if (tauntCooldown > 0) tauntCooldown -= dt;

    // 🚀 弹开或外部控制移动
    if (_externalTarget != null) {
      final delta = _externalTarget! - logicalPosition;
      final distance = delta.length;
      if (distance < 2) {
        logicalPosition = _externalTarget!;
        _externalTarget = null;
        isMoveLocked = false;
      } else {
        final moveStep = delta.normalized() * speed * dt;
        logicalPosition += moveStep;
        scale.x = delta.x < 0 ? -1 : 1;
      }
      return;
    }

    if (isMoveLocked) return;

    final dir = targetPosition - logicalPosition;
    final distance = dir.length;
    if (distance < 2) {
      pickNewTarget();
      return;
    }
    dir.normalize();
    final nextPos = logicalPosition + dir * speed * dt;

    if (spawner is FloatingIslandDynamicSpawnerComponent) {
      final nextTerrain = spawner.getTerrainType(nextPos);
      if (!spawner.allowedTerrains.contains(nextTerrain)) {
        pickNewTarget();
        return;
      }
    }

    logicalPosition = nextPos;

    final minX = movementBounds.left + size.x / 2;
    final maxX = movementBounds.right - size.x / 2;
    final minY = movementBounds.top + size.y / 2;
    final maxY = movementBounds.bottom - size.y / 2;

    if (minX <= maxX) {
      logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
    }
    if (minY <= maxY) {
      logicalPosition.y = logicalPosition.y.clamp(minY, maxY);
    }
  }

  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
    if (label != null) {
      label!.position = position - Vector2(0, size.y / 2 + 4);
    }
  }

  void pickNewTarget() {
    final rand = Random();
    Vector2 dir;
    do {
      dir = Vector2(rand.nextDouble() * 2 - 1, rand.nextDouble() * 2 - 1);
    } while (dir.length < 0.1);
    dir.normalize();
    final distance = minDistance + rand.nextDouble() * (maxDistance - minDistance);
    targetPosition = logicalPosition + dir * distance;
    scale.x = (targetPosition.x > logicalPosition.x) == defaultFacingRight ? 1 : -1;
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
      return;
    }

    if (collisionCooldown > 0) return;

    if (other is FloatingIslandDynamicMoverComponent && other != this) {
      final delta = logicalPosition - other.logicalPosition;

      final direction = delta.length > 0.01
          ? delta.normalized()
          : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

      final pushDistance = 8.0;

      logicalPosition += direction * pushDistance;
      other.logicalPosition -= direction * pushDistance;
      pickNewTarget();
    }

    collisionCooldown = 0.1;

    super.onCollision(points, other);
  }
}
