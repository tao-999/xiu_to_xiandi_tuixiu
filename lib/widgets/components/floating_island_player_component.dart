import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/player_sprite_util.dart';

import 'floating_island_monster_component.dart';

class FloatingIslandPlayerComponent extends SpriteComponent
    with HasGameReference, CollisionCallbacks {
  FloatingIslandPlayerComponent()
      : super(size: Vector2.all(32), anchor: Anchor.center);

  /// 🚀 逻辑世界坐标
  Vector2 logicalPosition = Vector2.zero();

  Vector2? _targetPosition;
  final double moveSpeed = 160;

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

    if (_targetPosition != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;

      if (distance <= 1.0) {
        logicalPosition = _targetPosition!;
        _targetPosition = null;
      } else {
        final moveStep = moveSpeed * dt;
        if (distance <= moveStep) {
          logicalPosition = _targetPosition!;
          _targetPosition = null;
        } else {
          logicalPosition += delta.normalized() * moveStep;
        }
      }

      // 翻转
      if (_targetPosition != null) {
        scale = Vector2(delta.x < 0 ? -1 : 1, 1);
      }

      // 通知
      _positionStreamController.add(logicalPosition);
    }
    // ✅ 实时Y排序（避免负数）
    priority = ((logicalPosition.y + 10000) * 1000).toInt();
  }

  @override
  void onRemove() {
    _positionStreamController.close();
    super.onRemove();
  }

  void notifyPositionChanged() {
    _positionStreamController.add(logicalPosition);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is FloatingIslandMonsterComponent) {
      // 计算反弹方向
      final delta = logicalPosition - other.logicalPosition;
      final rebound = delta.length > 0.01
          ? delta.normalized()
          : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

      // 🚀 立刻逻辑坐标小弹一下
      logicalPosition += rebound * 5;

      // 怪物也弹飞
      other.velocity = -other.velocity;
      other.setRandomDirection();

      debugPrint('[碰撞] 角色撞怪物！双方立刻小弹一下');
    }
  }
}
