// lib/widgets/components/floating_island_monster_component.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/collisions.dart';   // 🟢 别忘了！
import 'package:flutter/material.dart';

import 'floating_island_player_component.dart';

/// 🐲 无限地图怪物组件（支持地形限制 + 碰撞盒）
class FloatingIslandMonsterComponent extends SpriteComponent
    with CollisionCallbacks {
  /// 怪物出生时所在地形
  final String homeTerrain;

  /// 怪物可以巡逻的矩形区域
  final Rect allowedArea;

  /// 巡逻移动速度（像素/秒）
  final double moveSpeed;

  /// 当前移动方向
  Vector2 velocity = Vector2.zero();

  /// 逻辑坐标（世界坐标）
  Vector2 logicalPosition;

  /// 地形判定方法（传入世界坐标返回地形类型）
  final String Function(Vector2) getTerrainType;

  /// 随机生成器
  final Random _random = Random();

  FloatingIslandMonsterComponent({
    required this.homeTerrain,
    required this.allowedArea,
    required Vector2 initialPosition,
    required Sprite sprite,
    required this.getTerrainType,
    this.moveSpeed = 20.0,
    Vector2? size,
  })  : logicalPosition = initialPosition.clone(),
        super(
        sprite: sprite,
        position: Vector2.zero(),
        size: size ?? Vector2.all(24),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 添加矩形碰撞盒（可调试时 renderShape: true）
    add(RectangleHitbox()
      ..collisionType = CollisionType.active
      ..renderShape = false // true看边框，false隐藏
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (velocity == Vector2.zero()) {
      setRandomDirection();
    }

    final nextPos = logicalPosition + velocity * dt;

    // 判断即将要走的那一步的地形
    final currentTerrain = getTerrainType(nextPos);

    if (currentTerrain != homeTerrain) {
      // 踩到不是自己的地形就反方向转头/换方向
      setRandomDirection();
      velocity = -velocity;
      return;
    }

    logicalPosition = nextPos;

    // 超出区域后自动拉回边界并掉头
    if (!allowedArea.contains(Offset(logicalPosition.x, logicalPosition.y))) {
      logicalPosition.x = logicalPosition.x.clamp(
        allowedArea.left,
        allowedArea.right,
      );
      logicalPosition.y = logicalPosition.y.clamp(
        allowedArea.top,
        allowedArea.bottom,
      );
      setRandomDirection();
    }

    _handleMonsterCollisions();
  }

  void setRandomDirection() {
    final angle = _random.nextDouble() * 2 * pi;
    velocity = Vector2(cos(angle), sin(angle)) * moveSpeed;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is FloatingIslandPlayerComponent) {
      // 怪物反弹
      final delta = logicalPosition - other.logicalPosition;
      final rebound = delta.length > 0.01 ? delta.normalized() : (Vector2.random() - Vector2(0.5, 0.5)).normalized();
      logicalPosition += rebound * 24;
      velocity = -velocity;
      setRandomDirection();
      debugPrint('[碰撞] 怪物撞主角！双方弹飞，怪物掉头跑路！');
    }
  }

  void _handleMonsterCollisions() {
    // ⚡ 遍历同一 parent 下的所有怪物
    final siblings = parent?.children.whereType<FloatingIslandMonsterComponent>();
    if (siblings == null) return;

    for (final other in siblings) {
      if (identical(this, other)) continue;
      final minDist = (size.x + other.size.x) / 2 - 2;
      final delta = logicalPosition - other.logicalPosition;
      final dist = delta.length;
      if (dist < minDist && dist > 0.01) {
        final push = (minDist - dist) / 2;
        final move = delta.normalized() * push;
        logicalPosition += move;
        other.logicalPosition -= move;
        // ⚠️ 也可以顺便掉头
        setRandomDirection();
        other.setRandomDirection();
      }
    }
  }
}
