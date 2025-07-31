import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/player_sprite_util.dart';

import '../../utils/collision_logic_handler.dart';
import '../../utils/terrain_event_util.dart';
import 'floating_island_static_decoration_component.dart';
import 'resource_bar.dart';

class FloatingIslandPlayerComponent extends SpriteComponent
    with HasGameReference, CollisionCallbacks {
  FloatingIslandPlayerComponent({
    required this.resourceBarKey,
  }) : super(size: Vector2.all(32), anchor: Anchor.center, priority: 1000,);

  /// 🌍 资源栏 key，用于刷新 UI
  final GlobalKey<ResourceBarState> resourceBarKey;

  /// 🚀 逻辑世界坐标（用来移动、碰撞）
  Vector2 logicalPosition = Vector2.zero();

  Vector2? _targetPosition;
  final double moveSpeed = 120;

  // ✅ 用于外部监听逻辑坐标变化
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

    final path = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(path);

    // 屏幕中心
    position = game.size / 2;

    // 加碰撞盒
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // 初次通知
    _positionStreamController.add(logicalPosition);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 🚀 更新逻辑坐标
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

      // 翻转
      if (_targetPosition != null) {
        scale = Vector2(delta.x < 0 ? -1 : 1, 1);
      }

      // 通知
      _positionStreamController.add(logicalPosition);
    }

    // ✅ 同步 logicalOffset
    final mapGame = game as dynamic;
    if (_targetPosition != null) {
      mapGame.logicalOffset = logicalPosition.clone();
    }

    // ✅ 🆕 实时更新组件解锁状态
    final staticList = parent?.children
        .whereType<FloatingIslandStaticDecorationComponent>()
        .toList();
    if (staticList != null) {
      CollisionLogicHandler.updateLockStatus(logicalPosition, staticList);
    }

    // ✅ 异步触发地形事件（不阻塞主线程）
    final noiseGenerator = mapGame.noiseMapGenerator;
    final currentTerrain = noiseGenerator.getTerrainTypeAtPosition(logicalPosition);
    Future.microtask(() async {
      final triggered = await TerrainEventUtil.checkAndTrigger(currentTerrain, logicalPosition, game);
      if (triggered) {
        _targetPosition = null; // 停止移动
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
      resourceBarKey: resourceBarKey, // ✅ 加上传入
    );
  }
}
