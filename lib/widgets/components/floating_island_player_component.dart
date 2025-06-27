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
      : super(size: Vector2.all(48), anchor: Anchor.center);

  /// 🚀 逻辑世界坐标
  Vector2 logicalPosition = Vector2.zero();

  Vector2? _targetPosition;
  final double moveSpeed = 160;

  // ✅ 撞墙瞬间锁定
  bool _blocked = false;
  double _blockedTimer = 0.0;

  // ✅ 用于外部监听逻辑坐标变化
  final StreamController<Vector2> _positionStreamController = StreamController.broadcast();
  Stream<Vector2> get onPositionChangedStream => _positionStreamController.stream;

  void moveTo(Vector2 target) {
    _targetPosition = target;
    _blocked = false;
    _blockedTimer = 0;
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

    if (_blocked) {
      // 被弹后，短暂禁止移动
      _blockedTimer += dt;
      if (_blockedTimer > 0.18) { // 180ms冷却
        _blocked = false;
        _blockedTimer = 0;
      }
      return;
    }

    if (_targetPosition != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;

      // 检查目标点是否有怪物阻挡
      bool blockedByMonster = false;
      for (final monster in game.children.whereType<FloatingIslandMonsterComponent>()) {
        if ((monster.logicalPosition - (logicalPosition + delta.normalized() * 16)).length < 32) {
          blockedByMonster = true;
          break;
        }
      }

      if (blockedByMonster) {
        // 被怪物阻挡，立刻停止移动
        _targetPosition = null;
        debugPrint('[移动阻断] 有怪物在路上，主角自动停住');
        return;
      }

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
      // 主角弹弹反向
      final delta = logicalPosition - other.logicalPosition;
      final rebound = delta.length > 0.01 ? delta.normalized() : (Vector2.random() - Vector2(0.5, 0.5)).normalized();
      logicalPosition += rebound * 24; // 24像素弹飞
      other.velocity = -other.velocity;
      other.setRandomDirection();

      // 🚀 禁止主角移动，防穿模
      _blocked = true;
      _blockedTimer = 0;
      _targetPosition = null;

      debugPrint('[碰撞] 角色撞怪物！双方弹飞，主角停下！');
    }
  }
}
