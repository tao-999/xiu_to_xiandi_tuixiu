import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../utils/collision_logic_handler.dart';
import '../../utils/terrain_event_util.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_static_decoration_component.dart';
import 'resource_bar.dart';

class FloatingIslandPlayerComponent extends SpriteComponent
    with HasGameReference, CollisionCallbacks {
  FloatingIslandPlayerComponent({
    required this.resourceBarKey,
  }) : super(size: Vector2.all(32), anchor: Anchor.center, priority: 1000);

  final GlobalKey<ResourceBarState> resourceBarKey;
  Vector2 logicalPosition = Vector2.zero();
  Vector2? _targetPosition;
  final double moveSpeed = 120;

  final StreamController<Vector2> _positionStreamController = StreamController.broadcast();
  Stream<Vector2> get onPositionChangedStream => _positionStreamController.stream;

  void moveTo(Vector2 target) {
    _targetPosition = target;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final player = await PlayerStorage.getPlayer();
    if (player == null) {
      debugPrint('[FloatingIslandPlayerComponent] ⚠️ Player未初始化');
      return;
    }

    // ✅ 使用默认路径 icon_youli_${gender}.png
    final path = 'icon_youli_${player.gender}.png';
    final spriteImage = await Sprite.load(path);
    sprite = spriteImage;

    // ✅ 固定宽度32，高度按贴图比例缩放
    final originalSize = spriteImage.srcSize;
    final fixedWidth = 32.0;
    final scaledHeight = originalSize.y * (fixedWidth / originalSize.x);
    size = Vector2(fixedWidth, scaledHeight);

    position = game.size / 2;

    // ✅ 初始碰撞类型设为 passive，避免初始化瞬间误碰
    final hitbox = RectangleHitbox()
      ..size = size
      ..collisionType = CollisionType.passive;

    add(hitbox);

    // ✅ 延迟100ms后启用碰撞（active）
    Future.delayed(const Duration(milliseconds: 100), () {
      hitbox.collisionType = CollisionType.active;
      debugPrint('✅ 玩家碰撞激活完毕');
    });

    _positionStreamController.add(logicalPosition);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_targetPosition != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;
      final moveStep = moveSpeed * dt;

      if (distance <= moveStep) {
        logicalPosition = _targetPosition!;
        _targetPosition = null;
      } else {
        logicalPosition += delta.normalized() * moveStep;
      }

      if (_targetPosition != null) {
        scale = Vector2(delta.x < 0 ? -1 : 1, 1);
      }

      _positionStreamController.add(logicalPosition);
    }

    final mapGame = game as dynamic;
    if (_targetPosition != null) {
      mapGame.logicalOffset = logicalPosition.clone();
    }

    final staticList = parent?.children
        .whereType<FloatingIslandStaticDecorationComponent>()
        .toList();
    if (staticList != null) {
      CollisionLogicHandler.updateLockStatus(logicalPosition, staticList);
    }

    final noiseGenerator = mapGame.noiseMapGenerator;
    final currentTerrain = noiseGenerator.getTerrainTypeAtPosition(logicalPosition);
    Future.microtask(() async {
      final triggered = await TerrainEventUtil.checkAndTrigger(currentTerrain, logicalPosition, game);
      if (triggered) {
        _targetPosition = null;
      }
    });
  }

  @override
  void onRemove() {
    _positionStreamController.close();
    super.onRemove();
  }

  void notifyPositionChanged() {
    _positionStreamController.add(logicalPosition);
  }

  void stopMoving() {
    _targetPosition = null;
  }

  void syncVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  bool get isMoving => _targetPosition != null;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final mapGame = game as dynamic;

    CollisionLogicHandler.handleCollision(
      player: this,
      logicalOffset: mapGame.logicalOffset,
      other: other,
      resourceBarKey: resourceBarKey,
    );
  }
}
