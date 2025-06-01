// lib/widgets/components/maze_player_component.dart

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';

class MazePlayerComponent extends SpriteComponent with CollisionCallbacks, HasGameRef {
  final VoidCallback onCollideWithChest;
  final List<List<int>> grid;
  final double tileSize;

  List<Vector2> _path = [];
  int _currentStep = 0;
  final double _moveSpeed = 200;

  MazePlayerComponent({
    required Sprite sprite,
    required this.grid,
    required this.tileSize,
    required Vector2 position,
    required this.onCollideWithChest,
  }) : super(
    sprite: sprite,
    position: position,
    size: Vector2.all(48),
    anchor: Anchor.center,
    priority: 999,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void followPath(List<Vector2> path) {
    if (path.isEmpty) return;
    _path = path.map((p) => p * tileSize + Vector2.all(tileSize / 2)).toList();
    _currentStep = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_path.isNotEmpty && _currentStep < _path.length) {
      final target = _path[_currentStep];
      final direction = target - position;
      final distance = direction.length;
      final step = _moveSpeed * dt;

      if (distance <= step) {
        position = target;
        _currentStep++;

        // ✅ 路径走完时清空，恢复拖拽判断
        if (_currentStep >= _path.length) {
          _path = [];
        }
      } else {
        position += direction.normalized() * step;
      }

      // ✅ 地图跟随逻辑
      if (parent is PositionComponent && gameRef.size != Vector2.zero()) {
        final screenCenter = gameRef.size / 2;
        final container = parent as PositionComponent;
        final mapSize = Vector2(grid[0].length * tileSize, grid.length * tileSize);
        final desired = screenCenter - position;

        container.position = Vector2(
          desired.x.clamp(gameRef.size.x - mapSize.x, 0),
          desired.y.clamp(gameRef.size.y - mapSize.y, 0),
        );
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // ✅ 宝箱碰撞处理（你有需要再补）
  }

  /// 当前所在的格子坐标
  Vector2 get gridPosition => Vector2(
    (position.x / tileSize).floorToDouble(),
    (position.y / tileSize).floorToDouble(),
  );

  /// 是否正在移动，用于禁止拖拽
  bool get isMoving => _path.isNotEmpty;
}
