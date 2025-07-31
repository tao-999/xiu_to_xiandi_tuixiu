import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_player_component.dart';
import 'hp_bar_wrapper.dart';

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
  final bool enableMirror;

  final String? type;
  final String? labelText;
  final double? labelFontSize;
  final Color? labelColor;

  void Function(Set<Vector2> points, PositionComponent other)? onCustomCollision;
  TextComponent? label;

  bool isMoveLocked = false;
  Vector2? _externalTarget;

  double? hp; // ✅ 表示 maxHp
  double currentHp = 0; // ✅ 当前血量，动态变化
  double? atk;
  double? def;
  bool isDead = false;

  HpBarWrapper? hpBar;

  final bool enableAutoChase;
  final double? autoChaseRange;
  final String spawnedTileKey;
  final int? customPriority;

  FloatingIslandDynamicMoverComponent({
    required this.dynamicTileSize,
    required this.spawnedTileKey,
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
    this.enableAutoChase = false,
    this.autoChaseRange,
    this.enableMirror = true,
    this.customPriority,
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.bottomCenter,
        priority: customPriority ?? 11,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);

    currentHp = hp ?? 100; // ✅ 初始化当前血量

    if (labelText != null && labelText!.isNotEmpty) {
      label = TextComponent(
        text: labelText!,
        anchor: Anchor.bottomCenter,
        position: position - Vector2(0, size.y + 4),
        priority: 9999,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: labelFontSize ?? 12,
            color: labelColor ?? Colors.white,
          ),
        ),
      );
      parent?.add(label!);
    }

    if (hp != null && atk != null && def != null) {
      hpBar = HpBarWrapper()
        ..anchor = Anchor.bottomCenter
        ..position = position - Vector2(0, size.y + 24)
        ..priority = 9998;
      parent?.add(hpBar!);

      Future.delayed(Duration.zero, () {
        hpBar?.setStats(
          currentHp: currentHp.toInt(),
          maxHp: hp!.toInt(), // ✅ 使用 maxHp
          atk: atk!.toInt(),
          def: def!.toInt(),
        );
      });
    }

    pickNewTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    if (tauntCooldown > 0) {
      tauntCooldown -= dt;
      if (tauntCooldown < 0) tauntCooldown = 0;
    }

    if (enableAutoChase && autoChaseRange != null) {
      final player = game.descendants().whereType<FloatingIslandPlayerComponent>().firstOrNull;
      if (player != null) {
        final delta = player.logicalPosition - logicalPosition;
        final distance = delta.length;
        if (distance <= autoChaseRange!) {
          final moveStep = delta.normalized() * speed * dt;
          logicalPosition += moveStep;
          if (enableMirror) {
            scale.x = delta.x < 0 ? -1 : 1;
          }
          return;
        }
      }
    }

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
        if (enableMirror) {
          scale.x = delta.x < 0 ? -1 : 1;
        }
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
    label?.position = position - Vector2(0, size.y + 4);
    hpBar?.position = position - Vector2(0, size.y + 24);
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
    if (enableMirror) {
      scale.x = (targetPosition.x > logicalPosition.x) == defaultFacingRight ? 1 : -1;
    }
  }

  void moveToTarget(Vector2 target) {
    _externalTarget = target.clone();
    isMoveLocked = false;
    print('🎯 [Mover] 设置追击目标 = $_externalTarget');
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (isDead) return;

    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
      return;
    }

    super.onCollision(points, other);
  }
}

