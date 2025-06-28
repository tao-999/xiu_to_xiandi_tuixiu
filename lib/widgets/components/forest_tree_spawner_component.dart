import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 🌳 支持同一地形多贴图随机 + 稀疏分布的森林生成器
class ForestTreeSpawnerComponent extends Component {
  final double tileSize;
  final int seed;
  final Set<String> generatedTiles = {};
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2 worldPosition) getTerrainType;
  final Map<String, List<String>> terrainSpritesMap;
  final int minTreesPerTile;
  final int maxTreesPerTile;

  final List<_TreeWrapper> _trees = [];

  ForestTreeSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.terrainSpritesMap,
    this.tileSize = 128.0,
    this.seed = 8888,
    this.minTreesPerTile = 1,
    this.maxTreesPerTile = 3,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final logicalOffset = getLogicalOffset();
    final viewSize = getViewSize();

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

        if (terrainSpritesMap.containsKey(terrainType)) {
          _spawnTreesForTile(tx, ty, terrainType);
        }

        generatedTiles.add(key);
      }
    }

    // 每帧刷新位置
    for (final tree in _trees) {
      tree.component.position = tree.worldPosition - logicalOffset;
    }
  }

  Future<void> _spawnTreesForTile(int tileX, int tileY, String terrainType) async {
    final rand = Random(tileX * 92821 + tileY * 53987 + seed);

    // 🌿 稀疏分布：概率决定是否在这个tile生成树
    final tileSpawnChance = 0.5; // 50%概率
    if (rand.nextDouble() > tileSpawnChance) return;

    final count = rand.nextInt(maxTreesPerTile - minTreesPerTile + 1) + minTreesPerTile;

    final spriteList = terrainSpritesMap[terrainType]!;
    if (spriteList.isEmpty) return;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;

      final worldPos = Vector2(
        tileX * tileSize + offsetX,
        tileY * tileSize + offsetY,
      );

      final spritePath = spriteList[rand.nextInt(spriteList.length)];
      final sprite = await Sprite.load(spritePath);

      final tree = SpriteComponent(
        sprite: sprite,
        size: Vector2.all(42),
        anchor: Anchor.center,
      );

      grid.add(tree);

      _trees.add(_TreeWrapper(
        component: tree,
        worldPosition: worldPos,
      ));
    }
  }
}

/// 🌿简单封装：存 Sprite 和它的世界坐标
class _TreeWrapper {
  final SpriteComponent component;
  final Vector2 worldPosition;

  _TreeWrapper({
    required this.component,
    required this.worldPosition,
  });
}
