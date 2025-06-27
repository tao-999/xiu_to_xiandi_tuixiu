// lib/widgets/components/infinite_content_spawner_component.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'floating_island_monster_component.dart';

/// 🌟 无限地图内容生成器
/// 自动根据逻辑坐标生成怪物（只生成一次）
class InfiniteContentSpawnerComponent extends Component {
  /// Tile大小（像素）
  final double tileSize;

  /// 随机种子
  final int seed;

  /// 已生成的Tile坐标集合，防止重复生成
  final Set<String> generatedTiles = {};

  /// ✅ grid通过构造函数注入
  final Component grid;

  /// ✅ 逻辑偏移注入
  final Vector2 Function() getLogicalOffset;

  /// ✅ 视口大小注入
  final Vector2 Function() getViewSize;

  /// ✅ 获取Tile地形类型
  final String Function(Vector2 worldPosition) getTerrainType;

  /// ✅ 哪些地形会生成怪物
  final Set<String> allowedTerrains;

  InfiniteContentSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    this.tileSize = 128.0,
    this.seed = 9999,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final logicalOffset = getLogicalOffset();
    final viewSize = getViewSize();

    // 🚀 计算视口在世界坐标下的矩形
    final visibleLeftTop = logicalOffset - viewSize / 2;
    final visibleRightBottom = visibleLeftTop + viewSize;

    final startX = (visibleLeftTop.x / tileSize).floor();
    final startY = (visibleLeftTop.y / tileSize).floor();
    final endX = (visibleRightBottom.x / tileSize).ceil();
    final endY = (visibleRightBottom.y / tileSize).ceil();

    for (int tx = startX; tx < endX; tx++) {
      for (int ty = startY; ty < endY; ty++) {
        final key = '$tx:$ty';
        if (generatedTiles.contains(key)) continue;

        final tileCenter = Vector2(
          tx * tileSize + tileSize / 2,
          ty * tileSize + tileSize / 2,
        );

        final terrainType = getTerrainType(tileCenter);

        _spawnForTile(tx, ty, terrainType);

        generatedTiles.add(key);
      }
    }
  }

  /// 🌈 生成逻辑
  Future<void> _spawnForTile(int tileX, int tileY, String terrainType) async {
    final hash = _hash(tileX, tileY, seed);
    final chance = (hash % 1000) / 1000.0;

    // 🚀 只在允许的地形生成
    if (allowedTerrains.contains(terrainType) && chance < 0.2) {
      final sprite = await Sprite.load('floating_island/${terrainType}_monster.png');

      final monster = FloatingIslandMonsterComponent(
        homeTerrain: terrainType,
        allowedArea: Rect.fromLTWH(
          tileX * tileSize,
          tileY * tileSize,
          tileSize,
          tileSize,
        ),
        initialPosition: Vector2(
          tileX * tileSize + tileSize / 2,
          tileY * tileSize + tileSize / 2,
        ),
        sprite: sprite,
        moveSpeed: 30.0,
        getTerrainType: getTerrainType,   // ✅ 直接传递地形判定方法
        size: Vector2.all(64),
      );

      grid.add(monster);

      debugPrint('[Spawner] Monster spawned in $terrainType at Tile ($tileX, $tileY)');
    }
  }

  int _hash(int x, int y, int seed) {
    int n = x * 73856093 ^ y * 19349663 ^ seed * 83492791;
    return n & 0x7fffffff;
  }
}
