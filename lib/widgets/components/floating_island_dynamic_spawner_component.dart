import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_static_decoration_component.dart';

/// 🌈 通用动态漂移 + 静态生成器（数量、尺寸、tileSize都分开）
class FloatingIslandDynamicSpawnerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2 worldPos) getTerrainType;

  /// 静态贴图配置
  final Map<String, List<StaticSpriteEntry>> staticSpritesMap;

  /// 动态贴图配置
  final Map<String, List<DynamicSpriteEntry>> dynamicSpritesMap;

  final Set<String> allowedTerrains;

  /// 静态数量
  final int minStaticObjectsPerTile;
  final int maxStaticObjectsPerTile;

  /// 动态数量
  final int minDynamicObjectsPerTile;
  final int maxDynamicObjectsPerTile;

  /// 静态尺寸
  final double minStaticObjectSize;
  final double maxStaticObjectSize;

  /// 动态尺寸
  final double minDynamicObjectSize;
  final double maxDynamicObjectSize;

  /// 动态速度
  final double minSpeed;
  final double maxSpeed;

  /// 静态tileSize
  final double staticTileSize;

  /// 动态tileSize
  final double dynamicTileSize;

  /// 随机种子
  final int seed;

  /// 回调：动态逻辑
  final void Function(FloatingIslandDynamicMoverComponent mover, String terrainType)?
  onDynamicComponentCreated;

  /// 回调：静态逻辑
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
  });

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();

    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    // 🌿 静态网格
    final sStartX = (visibleTopLeft.x / staticTileSize).floor();
    final sStartY = (visibleTopLeft.y / staticTileSize).floor();
    final sEndX = (visibleBottomRight.x / staticTileSize).ceil();
    final sEndY = (visibleBottomRight.y / staticTileSize).ceil();

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

    // 🌊 动态网格
    final dStartX = (visibleTopLeft.x / dynamicTileSize).floor();
    final dStartY = (visibleTopLeft.y / dynamicTileSize).floor();
    final dEndX = (visibleBottomRight.x / dynamicTileSize).ceil();
    final dEndY = (visibleBottomRight.y / dynamicTileSize).ceil();

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

    // 🌿 刷新所有静态装饰
    for (final deco in grid.children.whereType<FloatingIslandStaticDecorationComponent>()) {
      deco.updateVisualPosition(offset);
      deco.priority = ((deco.worldPosition.y + 1e14) * 1000).toInt();
    }
  }

  /// 🌿 生成静态组件
  Future<void> _spawnStaticComponentsForTile(int tileX, int tileY, String terrain) async {
    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final rand = Random(seed + tileX * 92821 + tileY * 53987 + 1);

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) return;

    final count = rand.nextInt(maxStaticObjectsPerTile - minStaticObjectsPerTile + 1) +
        minStaticObjectsPerTile;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * staticTileSize;
      final offsetY = rand.nextDouble() * staticTileSize;

      final worldPos = Vector2(
        tileX * staticTileSize + offsetX,
        tileY * staticTileSize + offsetY,
      );

      final actualTerrain = getTerrainType(worldPos);
      if (!allowedTerrains.contains(actualTerrain)) continue;

      final selected = _pickStaticByWeight(entries, rand);
      final sprite = await Sprite.load(selected.path);

      final sizeValue = minStaticObjectSize +
          rand.nextDouble() * (maxStaticObjectSize - minStaticObjectSize);

      final deco = FloatingIslandStaticDecorationComponent(
        sprite: sprite,
        size: Vector2.all(sizeValue),
        worldPosition: worldPos,
        spritePath: selected.path,
      )..add(
        RectangleHitbox()..collisionType = CollisionType.passive,
      );

      onStaticComponentCreated?.call(deco, terrain);

      grid.add(deco);
    }
  }

  /// 🌊 生成动态组件
  Future<void> _spawnDynamicComponentsForTile(int tileX, int tileY, String terrain) async {
    final entries = dynamicSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final rand = Random(seed + tileX * 92821 + tileY * 53987 + 2);

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) return;

    final count = rand.nextInt(maxDynamicObjectsPerTile - minDynamicObjectsPerTile + 1) +
        minDynamicObjectsPerTile;

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * dynamicTileSize;
      final offsetY = rand.nextDouble() * dynamicTileSize;

      final worldPos = Vector2(
        tileX * dynamicTileSize + offsetX,
        tileY * dynamicTileSize + offsetY,
      );

      final actualTerrain = getTerrainType(worldPos);
      if (!allowedTerrains.contains(actualTerrain)) continue;

      final selected = _pickDynamicByWeight(entries, rand);
      final sprite = await Sprite.load(selected.path);

      final sizeValue = minDynamicObjectSize +
          rand.nextDouble() * (maxDynamicObjectSize - minDynamicObjectSize);

      final mover = FloatingIslandDynamicMoverComponent(
        sprite: sprite,
        position: worldPos,
        movementBounds: Rect.fromLTWH(
          tileX * dynamicTileSize,
          tileY * dynamicTileSize,
          dynamicTileSize,
          dynamicTileSize,
        ),
        speed: minSpeed + rand.nextDouble() * (maxSpeed - minSpeed),
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

  const StaticSpriteEntry(this.path, this.weight);
}

class DynamicSpriteEntry {
  final String path;
  final int weight;

  const DynamicSpriteEntry(this.path, this.weight);
}
