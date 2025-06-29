import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 🌈 通用地图装饰生成器
/// 支持多地形 -> 多贴图随机分布 + 尺寸随机
class TerrainDecorationSpawnerComponent extends Component {
  final double tileSize;
  final int seed;
  final Set<String> generatedTiles = {};
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2 worldPosition) getTerrainType;

  /// 地形名称 -> 装饰物Sprite路径列表
  final Map<String, List<String>> terrainSpritesMap;

  /// 每个Tile最少/最多刷几个
  final int minObjectsPerTile;
  final int maxObjectsPerTile;

  /// 装饰最小/最大尺寸（边长）
  final double minObjectSize;
  final double maxObjectSize;

  final List<_DecorationWrapper> _decorations = [];

  TerrainDecorationSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.terrainSpritesMap,
    this.tileSize = 128.0,
    this.seed = 8888,
    this.minObjectsPerTile = 1,
    this.maxObjectsPerTile = 3,
    this.minObjectSize = 16.0,
    this.maxObjectSize = 48.0,
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
          _spawnDecorationsForTile(tx, ty, terrainType);
        }

        generatedTiles.add(key);
      }
    }

    // 🌿 每帧刷新所有装饰位置 & priority
    for (final deco in _decorations) {
      // 更新屏幕位置
      deco.component.position = deco.worldPosition - logicalOffset;

      // 根据Y坐标实时设置priority
      deco.component.priority = (deco.worldPosition.y * 1000).toInt();
    }
  }

  Future<void> _spawnDecorationsForTile(int tileX, int tileY, String terrainType) async {
    final rand = Random(tileX * 92821 + tileY * 53987 + seed);

    // 🌿 稀疏分布：概率决定是否在这个tile生成
    final tileSpawnChance = 0.5; // 50%概率
    if (rand.nextDouble() > tileSpawnChance) return;

    final count = rand.nextInt(maxObjectsPerTile - minObjectsPerTile + 1) + minObjectsPerTile;

    final spriteList = terrainSpritesMap[terrainType]!;
    if (spriteList.isEmpty) return;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;

      final worldPos = Vector2(
        tileX * tileSize + offsetX,
        tileY * tileSize + offsetY,
      );

      // 🟢 二次检查生成点实际地形
      final actualTerrain = getTerrainType(worldPos);
      if (!terrainSpritesMap.containsKey(actualTerrain)) {
        continue; // 不符合的地形，不生成
      }

      final spritePath = spriteList[rand.nextInt(spriteList.length)];
      final sprite = await Sprite.load(spritePath);

      final sizeValue = minObjectSize +
          rand.nextDouble() * (maxObjectSize - minObjectSize);

      final deco = SpriteComponent(
        sprite: sprite,
        size: Vector2.all(sizeValue),
        anchor: Anchor.center,
      );

      deco.priority = worldPos.y.toInt();

      grid.add(deco);

      _decorations.add(_DecorationWrapper(
        component: deco,
        worldPosition: worldPos,
      ));
    }
  }
}

/// 🌿 存 Sprite 和它的世界坐标
class _DecorationWrapper {
  final SpriteComponent component;
  final Vector2 worldPosition;

  _DecorationWrapper({
    required this.component,
    required this.worldPosition,
  });
}
