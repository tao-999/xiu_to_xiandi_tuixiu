import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_player_component.dart';

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
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.center,
      );

  void moveTo(Vector2 target) {
    _externalTarget = target;
    isMoveLocked = true;
  }

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

    // 🚀 如果处于被外部移动阶段（弹开）
    if (_externalTarget != null) {
      final delta = _externalTarget! - logicalPosition;
      final distance = delta.length;

      if (distance < 2) {
        logicalPosition = _externalTarget!;
        _externalTarget = null;
        isMoveLocked = false; // 🟢 解锁，恢复游走
      } else {
        final moveStep = delta.normalized() * speed * dt;
        logicalPosition += moveStep;
        scale.x = delta.x < 0 ? -1 : 1;
      }
      return;
    }

    // 🔒 锁定中，不游走
    if (isMoveLocked) return;

    // ✅ 正常游走逻辑
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

    logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
    logicalPosition.y = logicalPosition.y.clamp(minY, maxY);
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

    if (other is FloatingIslandPlayerComponent ||
        other is FloatingIslandDynamicMoverComponent) {
      final otherPos = other is FloatingIslandPlayerComponent
          ? other.logicalPosition
          : (other as FloatingIslandDynamicMoverComponent).logicalPosition;

      final delta = logicalPosition - otherPos;
      final direction = delta.length > 1e-3
          ? delta.normalized()
          : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

      final offset = direction * 64;
      moveTo(logicalPosition + offset);
    } else {
      pickNewTarget();
    }

    collisionCooldown = 0.5;

    super.onCollision(points, other);
  }
}
