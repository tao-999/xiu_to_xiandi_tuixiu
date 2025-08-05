import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../../services/collected_pill_storage.dart';
import '../../services/dead_boss_storage.dart';
import '../../utils/name_generator.dart';
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

  final void Function(FloatingIslandDynamicMoverComponent mover, String terrainType)?
  onDynamicComponentCreated;

  final Set<String> _loadedDynamicTiles = <String>{};
  Set<String> get loadedDynamicTiles => _loadedDynamicTiles;

  final Map<String, Sprite> _spriteCache = {};
  final List<_PendingTile> _pendingTiles = [];

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
  Future<void> onLoad() async {
    for (final entries in dynamicSpritesMap.values) {
      for (final entry in entries) {
        if (!_spriteCache.containsKey(entry.path)) {
          _spriteCache[entry.path] = await Sprite.load(entry.path);
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    _collectPendingTiles(visibleTopLeft, visibleBottomRight);

    const int tilesPerFrame = 1;
    int spawned = 0;
    while (_pendingTiles.isNotEmpty && spawned < tilesPerFrame) {
      final tile = _pendingTiles.removeAt(0);
      _spawnDynamicComponentsForTile(tile.tx, tile.ty, tile.terrain);
      spawned++;
    }
  }

  /// 🔍 从地图中随机挑选一个允许地形的 tile，返回其中心坐标
  Vector2? findRandomValidTile() {
    final rand = Random(seed); // 保持随机一致性
    final checked = <String>{};
    final resultTiles = <Vector2>[];

    // 粗略从已加载过的 tile 中找一块合法的
    for (final tileKey in _loadedDynamicTiles) {
      final parts = tileKey.split('_');
      if (parts.length < 2) continue;

      final tx = int.tryParse(parts[0]);
      final ty = int.tryParse(parts[1]);
      if (tx == null || ty == null) continue;

      final center = Vector2(
        tx * dynamicTileSize + dynamicTileSize / 2,
        ty * dynamicTileSize + dynamicTileSize / 2,
      );

      final terrain = getTerrainType(center);
      if (allowedTerrains.contains(terrain)) {
        resultTiles.add(center);
      }
    }

    // 如果找到了合法地形块，就随机挑一个返回
    if (resultTiles.isNotEmpty) {
      return resultTiles[rand.nextInt(resultTiles.length)].clone();
    }

    // 如果 _loadedDynamicTiles 为空，也可以 fallback 返回中央区域
    print('⚠️ [Spawner] 没有找到合法的动态 tile，默认返回地图中央');
    return Vector2(0, 0); // 可替换为地图中心或初始点
  }

  void _collectPendingTiles(Vector2 topLeft, Vector2 bottomRight) {
    final dStartX = (topLeft.x / dynamicTileSize).floor();
    final dStartY = (topLeft.y / dynamicTileSize).floor();
    final dEndX = (bottomRight.x / dynamicTileSize).ceil();
    final dEndY = (bottomRight.y / dynamicTileSize).ceil();

    final center = getLogicalOffset();
    final List<_PendingTile> newlyFound = [];

    for (int tx = dStartX; tx < dEndX; tx++) {
      for (int ty = dStartY; ty < dEndY; ty++) {
        final tileCenter = Vector2(
          tx * dynamicTileSize + dynamicTileSize / 2,
          ty * dynamicTileSize + dynamicTileSize / 2,
        );

        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        final typesInThisSpawner = dynamicSpritesMap[terrain]?.map((e) => e.type ?? 'null').toSet() ?? {'null'};
        for (final type in typesInThisSpawner) {
          final tileKey = '${tx}_${ty}_$type';
          if (_loadedDynamicTiles.contains(tileKey)) continue;

          _loadedDynamicTiles.add(tileKey);
          newlyFound.add(_PendingTile(tx, ty, terrain));
        }
      }
    }

    newlyFound.sort((a, b) {
      final d1 = (a.center(dynamicTileSize) - center).length;
      final d2 = (b.center(dynamicTileSize) - center).length;
      return d1.compareTo(d2);
    });

    _pendingTiles.addAll(newlyFound);
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
    final tileCenter = Vector2(tx * tileSize + tileSize / 2, ty * tileSize + tileSize / 2);

    final type = selected.type ?? 'null';
    final tileKey = '${tx}_${ty}_$type';

    // ✅ Boss 已死亡跳过
    if (await DeadBossStorage.isDead(tileKey)) return;
    // ✅ 丹药已拾取跳过（只针对丹药组件）
    if (type.startsWith('danyao_')) {
      final alreadyCollected = await CollectedPillStorage.isCollected(tileKey);
      if (alreadyCollected) return;
    }

    final count = rand.nextInt(maxCount - minCount + 1) + minCount;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(tx * tileSize + offsetX, ty * tileSize + offsetY);

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final sprite = _spriteCache[selected.path]!;
      final originalSize = sprite.srcSize;

      Vector2 sizeValue;
      if (selected.desiredWidth != null) {
        final factor = selected.desiredWidth! / originalSize.x;
        sizeValue = originalSize * factor;
      } else {
        final minSize = selected.minSize ?? minDynamicObjectSize;
        final maxSize = selected.maxSize ?? maxDynamicObjectSize;
        final scale = minSize + rand.nextDouble() * (maxSize - minSize);
        final factor = scale / originalSize.x;
        sizeValue = originalSize * factor;
      }

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
        bounds = Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);
      }

      // ✅ 随机名称
      String? finalLabelText;
      if (selected.generateRandomLabel == true) {
        final nameSeedKey = '${tx}_${ty}_${i}_${selected.path}_$type';
        final nameRand = Random(seed + nameSeedKey.hashCode);
        finalLabelText = NameGenerator.generateWithSeed(nameRand, isMale: true);
      } else {
        finalLabelText = selected.labelText;
      }

      final dist = worldPos.length;
      final hp = selected.hp != null ? (selected.hp! + dist / 10) : null;
      final atk = selected.atk != null ? (selected.atk! + dist / 50) : null;
      final def = selected.def != null ? (selected.def! + dist / 80) : null;

      final mover = FloatingIslandDynamicMoverComponent(
        spawner: this,
        dynamicTileSize: dynamicTileSize,
        sprite: sprite,
        position: worldPos,
        movementBounds: bounds,
        speed: speedValue,
        size: sizeValue,
        spritePath: selected.path,
        defaultFacingRight: selected.defaultFacingRight,
        minDistance: selected.minDistance ?? 500.0,
        maxDistance: selected.maxDistance ?? 2000.0,
        labelText: finalLabelText,
        labelFontSize: selected.labelFontSize,
        labelColor: selected.labelColor,
        type: type,
        hp: hp,
        atk: atk,
        def: def,
        enableAutoChase: selected.enableAutoChase ?? false,
        autoChaseRange: selected.autoChaseRange,
        spawnedTileKey: tileKey,
        enableMirror: selected.enableMirror,
        customPriority: selected.priority,
        ignoreTerrainInMove: selected.ignoreTerrainInMove,
      );

      onDynamicComponentCreated?.call(mover, terrain);
      mover.onRemoveCallback = () {
        _loadedDynamicTiles.remove(tileKey);
      };

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

class _PendingTile {
  final int tx;
  final int ty;
  final String terrain;

  _PendingTile(this.tx, this.ty, this.terrain);

  Vector2 center(double tileSize) {
    return Vector2(
      tx * tileSize + tileSize / 2,
      ty * tileSize + tileSize / 2,
    );
  }
}
