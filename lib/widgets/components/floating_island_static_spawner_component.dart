import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import 'floating_island_static_decoration_component.dart';

class FloatingIslandStaticSpawnerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2) getTerrainType;
  final Set<String> allowedTerrains;
  final Map<String, List<StaticSpriteEntry>> staticSpritesMap;
  final double staticTileSize;
  final int seed;

  /// 🌟全局默认数量
  final int minCount;
  final int maxCount;

  /// 🌟全局默认大小
  final double minSize;
  final double maxSize;

  final void Function(FloatingIslandStaticDecorationComponent deco, String terrainType)?
  onStaticComponentCreated;

  FloatingIslandStaticSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    required this.staticSpritesMap,
    this.staticTileSize = 128.0,
    this.seed = 8888,
    this.minCount = 1,
    this.maxCount = 2,
    this.minSize = 16.0,
    this.maxSize = 48.0,
    this.onStaticComponentCreated,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    _processStaticTiles(visibleTopLeft, visibleBottomRight);

    for (final deco in grid.children.whereType<FloatingIslandStaticDecorationComponent>()) {
      deco.updateVisualPosition(offset);
      deco.priority = ((deco.worldPosition.y + 1e14) * 1000).toInt();
    }
  }

  void _processStaticTiles(Vector2 topLeft, Vector2 bottomRight) {
    final sStartX = (topLeft.x / staticTileSize).floor();
    final sStartY = (topLeft.y / staticTileSize).floor();
    final sEndX = (bottomRight.x / staticTileSize).ceil();
    final sEndY = (bottomRight.y / staticTileSize).ceil();

    for (int tx = sStartX; tx < sEndX; tx++) {
      for (int ty = sStartY; ty < sEndY; ty++) {
        final tileCenter = Vector2(
          tx * staticTileSize + staticTileSize / 2,
          ty * staticTileSize + staticTileSize / 2,
        );

        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        final rand = Random(seed + tx * 92821 + ty * 53987 + 1);
        final tileSpawnChance = 0.5;
        if (rand.nextDouble() > tileSpawnChance) continue;

        final entries = staticSpritesMap[terrain] ?? [];
        if (entries.isEmpty) continue;

        final selected = _pickStaticByWeight(entries, rand);
        final tileSize = selected.tileSize ?? staticTileSize;

        // ✅判断是否已有组件，依然用staticTileSize
        final alreadyExists = grid.children.any((c) {
          if (c is FloatingIslandStaticDecorationComponent) {
            final pos = c.worldPosition;
            return pos.x >= tx * staticTileSize &&
                pos.x < (tx + 1) * staticTileSize &&
                pos.y >= ty * staticTileSize &&
                pos.y < (ty + 1) * staticTileSize;
          }
          return false;
        });

        if (alreadyExists) continue;

        _spawnStaticComponentsForTile(tx, ty, terrain, selected, rand, tileSize);
      }
    }
  }

  Future<void> _spawnStaticComponentsForTile(
      int tx,
      int ty,
      String terrain,
      StaticSpriteEntry selected,
      Random rand,
      double tileSize) async {
    final entryMinCount = selected.minCount ?? minCount;
    final entryMaxCount = selected.maxCount ?? maxCount;
    final count = rand.nextInt(entryMaxCount - entryMinCount + 1) + entryMinCount;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(
        tx * tileSize + offsetX,
        ty * tileSize + offsetY,
      );

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final sprite = await Sprite.load(selected.path);
      final minS = selected.minSize ?? minSize;
      final maxS = selected.maxSize ?? maxSize;
      final sizeValue = minS + rand.nextDouble() * (maxS - minS);

      final deco = FloatingIslandStaticDecorationComponent(
        sprite: sprite,
        size: Vector2.all(sizeValue),
        worldPosition: worldPos,
        spritePath: selected.path,
      )..add(RectangleHitbox()..collisionType = CollisionType.passive);

      onStaticComponentCreated?.call(deco, terrain);
      grid.add(deco);
    }
  }

  StaticSpriteEntry _pickStaticByWeight(List<StaticSpriteEntry> entries, Random rand) {
    final totalWeight = entries.fold<int>(0, (sum, e) => sum + e.weight);
    final roll = rand.nextInt(totalWeight);
    int cumulative = 0;
    for (final entry in entries) {
      cumulative += entry.weight;
      if (roll < cumulative) {
        return entry;
      }
    }
    return entries.first;
  }
}

/// 🌟 静态贴图配置
class StaticSpriteEntry {
  final String path;
  final int weight;
  final double? minSize;
  final double? maxSize;
  final int? minCount;
  final int? maxCount;
  final double? tileSize;

  const StaticSpriteEntry(
      this.path,
      this.weight, {
        this.minSize,
        this.maxSize,
        this.minCount,
        this.maxCount,
        this.tileSize,
      });
}
