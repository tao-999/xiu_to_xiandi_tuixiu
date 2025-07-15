import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
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
  final String? spritePath;
  final dynamic spawner;
  final double dynamicTileSize;
  final bool defaultFacingRight;
  final double minDistance;
  final double maxDistance;

  final String? labelText;
  final double? labelFontSize;
  final Color? labelColor;

  String? collisionText;
  void Function(Set<Vector2> points, PositionComponent other)? onCustomCollision;
  TextComponent? label;

  double _lastCollisionTextTime = 0;

  FloatingIslandDynamicMoverComponent({
    required this.dynamicTileSize,
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
    this.collisionText,
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

    if (minX >= maxX || minY >= maxY) {
      logicalPosition = movementBounds.center.toVector2();
    } else {
      logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
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
      dir = Vector2(
        rand.nextDouble() * 2 - 1,
        rand.nextDouble() * 2 - 1,
      );
    } while (dir.length < 0.1);

    dir.normalize();
    final distance = minDistance + rand.nextDouble() * (maxDistance - minDistance);
    targetPosition = logicalPosition + dir * distance;

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
      if (other is FloatingIslandPlayerComponent || other is FloatingIslandDynamicMoverComponent) {
        final otherLogicalPosition = other is FloatingIslandPlayerComponent
            ? other.logicalPosition
            : (other as FloatingIslandDynamicMoverComponent).logicalPosition;

        final delta = logicalPosition - otherLogicalPosition;
        final rebound = delta.length > 0.01
            ? delta.normalized()
            : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

        // 🚀平滑弹开
        final offset = rebound * 10;
        add(
          MoveEffect.by(
            offset,
            EffectController(duration: 0.15, curve: Curves.easeOut),
          ),
        );

        if (other is FloatingIslandPlayerComponent) {
          other.add(
            MoveEffect.by(
              -offset / 2,
              EffectController(duration: 0.15, curve: Curves.easeOut),
            ),
          );
        } else if (other is FloatingIslandDynamicMoverComponent) {
          other.add(
            MoveEffect.by(
              -offset / 2,
              EffectController(duration: 0.15, curve: Curves.easeOut),
            ),
          );
        }

        pickNewTarget();
        collisionCooldown = 0.5;

        if (other is FloatingIslandPlayerComponent && collisionText != null && collisionText!.isNotEmpty) {
          _showCollisionText();
        }
      } else {
        pickNewTarget();
        collisionCooldown = 0.5;
      }
    }

    super.onCollision(points, other);
  }

  void _showCollisionText() {
    final now = game.currentTime();
    if (now - _lastCollisionTextTime < 1.0) {
      return;
    }
    _lastCollisionTextTime = now;

    final textComponent = TextComponent(
      text: collisionText!,
      anchor: Anchor.bottomCenter,
      position: position - Vector2(0, size.y / 2 + 4),
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF6666),
          fontSize: 11,
        ),
      ),
    );

    textComponent.add(
      MoveEffect.by(
        Vector2(0, -32),
        EffectController(duration: 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      textComponent.removeFromParent();
    });

    parent?.add(textComponent);
  }
}
