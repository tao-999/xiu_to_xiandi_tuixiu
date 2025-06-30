// lib/widgets/components/floating_island_dynamic_spawner_component.dart

import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/terrain_utils.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_static_decoration_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandDynamicSpawnerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2 worldPos) getTerrainType;
  final NoiseTileMapGenerator? noiseMapGenerator;

  final Map<String, List<StaticSpriteEntry>> staticSpritesMap;
  final Map<String, List<DynamicSpriteEntry>> dynamicSpritesMap;
  final Set<String> allowedTerrains;

  final double staticTileSize;
  final double dynamicTileSize;
  final int seed;

  final int minStaticObjectsPerTile;
  final int maxStaticObjectsPerTile;
  final int minDynamicObjectsPerTile;
  final int maxDynamicObjectsPerTile;

  final double minStaticObjectSize;
  final double maxStaticObjectSize;
  final double minDynamicObjectSize;
  final double maxDynamicObjectSize;

  final double minSpeed;
  final double maxSpeed;

  final void Function(FloatingIslandDynamicMoverComponent mover, String terrainType)?
  onDynamicComponentCreated;

  final void Function(FloatingIslandStaticDecorationComponent deco, String terrainType)?
  onStaticComponentCreated;

  final Set<String> generatedStaticTiles = {};
  final Set<String> generatedDynamicTiles = {};

  FloatingIslandDynamicSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    required this.staticSpritesMap,
    required this.dynamicSpritesMap,
    this.staticTileSize = 128.0,
    this.dynamicTileSize = 64.0,
    this.seed = 8888,
    this.minStaticObjectsPerTile = 1,
    this.maxStaticObjectsPerTile = 2,
    this.minDynamicObjectsPerTile = 1,
    this.maxDynamicObjectsPerTile = 2,
    this.minStaticObjectSize = 16.0,
    this.maxStaticObjectSize = 48.0,
    this.minDynamicObjectSize = 32.0,
    this.maxDynamicObjectSize = 64.0,
    this.minSpeed = 10.0,
    this.maxSpeed = 50.0,
    this.onDynamicComponentCreated,
    this.onStaticComponentCreated,
    this.noiseMapGenerator,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();

    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    // 🌿 静态网格
    _processStaticTiles(visibleTopLeft, visibleBottomRight);

    // 🌊 动态网格
    _processDynamicTiles(visibleTopLeft, visibleBottomRight);

    // 🪧 刷新静态装饰位置和层级
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
        final key = '$tx:$ty';
        if (generatedStaticTiles.contains(key)) continue;

        final tileCenter = Vector2(
          tx * staticTileSize + staticTileSize / 2,
          ty * staticTileSize + staticTileSize / 2,
        );

        final terrain = getTerrainType(tileCenter);
        if (allowedTerrains.contains(terrain)) {
          _spawnStaticComponentsForTile(tx, ty, terrain);
        }

        generatedStaticTiles.add(key);
      }
    }
  }

  void _processDynamicTiles(Vector2 topLeft, Vector2 bottomRight) {
    final dStartX = (topLeft.x / dynamicTileSize).floor();
    final dStartY = (topLeft.y / dynamicTileSize).floor();
    final dEndX = (bottomRight.x / dynamicTileSize).ceil();
    final dEndY = (bottomRight.y / dynamicTileSize).ceil();

    for (int tx = dStartX; tx < dEndX; tx++) {
      for (int ty = dStartY; ty < dEndY; ty++) {
        final key = '$tx:$ty';
        if (generatedDynamicTiles.contains(key)) continue;

        final tileCenter = Vector2(
          tx * dynamicTileSize + dynamicTileSize / 2,
          ty * dynamicTileSize + dynamicTileSize / 2,
        );

        final terrain = getTerrainType(tileCenter);
        if (allowedTerrains.contains(terrain)) {
          _spawnDynamicComponentsForTile(tx, ty, terrain);
        }

        generatedDynamicTiles.add(key);
      }
    }
  }

  Future<void> _spawnStaticComponentsForTile(int tx, int ty, String terrain) async {
    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final rand = Random(seed + tx * 92821 + ty * 53987 + 1);

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) return;

    final selected = _pickStaticByWeight(entries, rand);

    final minCount = selected.minCount ?? minStaticObjectsPerTile;
    final maxCount = selected.maxCount ?? maxStaticObjectsPerTile;
    final tileSize = selected.tileSize ?? staticTileSize;

    final count = rand.nextInt(maxCount - minCount + 1) + minCount;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(
        tx * tileSize + offsetX,
        ty * tileSize + offsetY,
      );

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final sprite = await Sprite.load(selected.path);

      final minSize = selected.minSize ?? minStaticObjectSize;
      final maxSize = selected.maxSize ?? maxStaticObjectSize;
      final sizeValue = minSize + rand.nextDouble() * (maxSize - minSize);

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

  Future<void> _spawnDynamicComponentsForTile(int tx, int ty, String terrain) async {
    final entries = dynamicSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final rand = Random(seed + tx * 92821 + ty * 53987 + 2);

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) return;

    final selected = _pickDynamicByWeight(entries, rand);

    final minCount = selected.minCount ?? minDynamicObjectsPerTile;
    final maxCount = selected.maxCount ?? maxDynamicObjectsPerTile;
    final tileSize = selected.tileSize ?? dynamicTileSize;

    final count = rand.nextInt(maxCount - minCount + 1) + minCount;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;

      final worldPos = Vector2(
        tx * tileSize + offsetX,
        ty * tileSize + offsetY,
      );

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final sprite = await Sprite.load(selected.path);

      final minSize = selected.minSize ?? minDynamicObjectSize;
      final maxSize = selected.maxSize ?? maxDynamicObjectSize;
      final sizeValue = minSize + rand.nextDouble() * (maxSize - minSize);

      final minSpd = selected.minSpeed ?? minSpeed;
      final maxSpd = selected.maxSpeed ?? maxSpeed;
      final speedValue = minSpd + rand.nextDouble() * (maxSpd - minSpd);

      Rect bounds;
      if (noiseMapGenerator != null) {
        bounds = TerrainUtils.floodFillBoundingBox(
          start: worldPos,
          terrainType: terrain,
          getTerrainType: (pos) => noiseMapGenerator!.getTerrainTypeAtPosition(pos),
          sampleStep: 32.0,
          maxSteps: 2000,
        );
      } else {
        bounds = Rect.fromLTWH(
          tx * tileSize,
          ty * tileSize,
          tileSize,
          tileSize,
        );
      }

      final mover = FloatingIslandDynamicMoverComponent(
        sprite: sprite,
        position: worldPos,
        movementBounds: bounds,
        speed: speedValue,
        size: Vector2.all(sizeValue),
        spritePath: selected.path,
      );

      onDynamicComponentCreated?.call(mover, terrain);
      grid.add(mover);
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

  DynamicSpriteEntry _pickDynamicByWeight(List<DynamicSpriteEntry> entries, Random rand) {
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

class DynamicSpriteEntry {
  final String path;
  final int weight;
  final double? minSize;
  final double? maxSize;
  final int? minCount;
  final int? maxCount;
  final double? tileSize;
  final double? minSpeed;
  final double? maxSpeed;

  const DynamicSpriteEntry(
      this.path,
      this.weight, {
        this.minSize,
        this.maxSize,
        this.minCount,
        this.maxCount,
        this.tileSize,
        this.minSpeed,
        this.maxSpeed,
      });
}
