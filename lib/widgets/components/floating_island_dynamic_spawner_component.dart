import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../../utils/terrain_utils.dart';
import 'dynamic_sprite_entry.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandDynamicSpawnerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2) getTerrainType;
  final NoiseTileMapGenerator? noiseMapGenerator;

  final Map<String, List<DynamicSpriteEntry>> dynamicSpritesMap;
  final Set<String> allowedTerrains;

  final double dynamicTileSize;
  final int seed;

  final int minDynamicObjectsPerTile;
  final int maxDynamicObjectsPerTile;

  final double minDynamicObjectSize;
  final double maxDynamicObjectSize;

  final double minSpeed;
  final double maxSpeed;

  /// 已加载的tile
  final Set<String> _loadedDynamicTiles = <String>{};

  Set<String> get loadedDynamicTiles => _loadedDynamicTiles;

  /// 创建回调
  final void Function(FloatingIslandDynamicMoverComponent mover, String terrainType)?
  onDynamicComponentCreated;

  FloatingIslandDynamicSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    required this.dynamicSpritesMap,
    this.dynamicTileSize = 64.0,
    this.seed = 8888,
    this.minDynamicObjectsPerTile = 1,
    this.maxDynamicObjectsPerTile = 2,
    this.minDynamicObjectSize = 32.0,
    this.maxDynamicObjectSize = 64.0,
    this.minSpeed = 10.0,
    this.maxSpeed = 50.0,
    this.onDynamicComponentCreated,
    this.noiseMapGenerator,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();

    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    _processDynamicTiles(visibleTopLeft, visibleBottomRight);
  }

  void _processDynamicTiles(Vector2 topLeft, Vector2 bottomRight) {
    final dStartX = (topLeft.x / dynamicTileSize).floor();
    final dStartY = (topLeft.y / dynamicTileSize).floor();
    final dEndX = (bottomRight.x / dynamicTileSize).ceil();
    final dEndY = (bottomRight.y / dynamicTileSize).ceil();

    for (int tx = dStartX; tx < dEndX; tx++) {
      for (int ty = dStartY; ty < dEndY; ty++) {
        final tileKey = '${tx}_${ty}';
        if (_loadedDynamicTiles.contains(tileKey)) continue;

        final tileCenter = Vector2(
          tx * dynamicTileSize + dynamicTileSize / 2,
          ty * dynamicTileSize + dynamicTileSize / 2,
        );

        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        _spawnDynamicComponentsForTile(tx, ty, terrain);
        _loadedDynamicTiles.add(tileKey);
      }
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
        spawner: this,
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
