import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/static_sprite_entry.dart';

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

  final int minCount;
  final int maxCount;
  final double minSize;
  final double maxSize;

  final void Function(FloatingIslandStaticDecorationComponent deco, String terrainType)?
  onStaticComponentCreated;

  /// 每帧需要生成的tile队列
  final List<_PendingTile> _pendingTiles = [];

  /// 当前已经在内存的tile key，避免重复生成
  final Set<String> _activeTiles = {};

  /// 上一次逻辑中心
  Vector2? _lastLogicalOffset;

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

    // 🚀 如果逻辑坐标没动，直接return
    if (_lastLogicalOffset != null && (_lastLogicalOffset! - offset).length < 1) {
      for (final deco in grid.children.whereType<FloatingIslandStaticDecorationComponent>()) {
        deco.updateVisualPosition(offset);
        deco.priority = ((deco.worldPosition.y + 1e14) * 1000).toInt();
      }
      return;
    }

    // 更新记录
    _lastLogicalOffset = offset.clone();

    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    // 视野 *1.5 buffer
    final bufferExtent = viewSize * 0.75;
    final bufferTopLeft = offset - bufferExtent;
    final bufferBottomRight = offset + bufferExtent;

    // 清理超出buffer的tile key
    _activeTiles.removeWhere((key) {
      final parts = key.split('_');
      final tx = int.tryParse(parts[0]) ?? 0;
      final ty = int.tryParse(parts[1]) ?? 0;
      final tileCenterX = tx * staticTileSize + staticTileSize / 2;
      final tileCenterY = ty * staticTileSize + staticTileSize / 2;

      return tileCenterX < bufferTopLeft.x ||
          tileCenterX > bufferBottomRight.x ||
          tileCenterY < bufferTopLeft.y ||
          tileCenterY > bufferBottomRight.y;
    });

    // ⚡清理超出buffer的组件
    for (final deco in grid.children.whereType<FloatingIslandStaticDecorationComponent>()) {
      final pos = deco.worldPosition;
      if (pos.x < bufferTopLeft.x ||
          pos.x > bufferBottomRight.x ||
          pos.y < bufferTopLeft.y ||
          pos.y > bufferBottomRight.y) {
        final tx = (pos.x / staticTileSize).floor();
        final ty = (pos.y / staticTileSize).floor();
        _activeTiles.remove('${tx}_${ty}');
        deco.removeFromParent();
      } else {
        deco.updateVisualPosition(offset);
        deco.priority = ((deco.worldPosition.y + 1e14) * 1000).toInt();
      }
    }

    // 收集新tile
    _collectPendingTiles(visibleTopLeft, visibleBottomRight);

    // 本帧生成
    final tilesPerFrame = _pendingTiles.length;
    int spawned = 0;
    while (_pendingTiles.isNotEmpty && spawned < tilesPerFrame) {
      final tile = _pendingTiles.removeAt(0);
      _spawnTile(tile.tx, tile.ty, tile.terrain);
      spawned++;
    }
  }

  void _collectPendingTiles(Vector2 topLeft, Vector2 bottomRight) {
    final sStartX = (topLeft.x / staticTileSize).floor();
    final sStartY = (topLeft.y / staticTileSize).floor();
    final sEndX = (bottomRight.x / staticTileSize).ceil();
    final sEndY = (bottomRight.y / staticTileSize).ceil();

    final center = getLogicalOffset();
    final newlyFound = <_PendingTile>[];

    for (int tx = sStartX; tx < sEndX; tx++) {
      for (int ty = sStartY; ty < sEndY; ty++) {
        final tileKey = '${tx}_${ty}';

        if (_activeTiles.contains(tileKey)) continue;

        bool alreadyExists = false;
        if (_pendingTiles.isEmpty) {
          alreadyExists = grid.children.any((c) {
            if (c is FloatingIslandStaticDecorationComponent) {
              final pos = c.worldPosition;
              return pos.x >= tx * staticTileSize &&
                  pos.x < (tx + 1) * staticTileSize &&
                  pos.y >= ty * staticTileSize &&
                  pos.y < (ty + 1) * staticTileSize;
            }
            return false;
          });
        }

        if (alreadyExists) {
          _activeTiles.add(tileKey);
          continue;
        }

        final tileCenter = Vector2(
          tx * staticTileSize + staticTileSize / 2,
          ty * staticTileSize + staticTileSize / 2,
        );
        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        newlyFound.add(_PendingTile(tx, ty, terrain));
      }
    }

    newlyFound.sort((a, b) {
      final d1 = (a.center(staticTileSize) - center).length;
      final d2 = (b.center(staticTileSize) - center).length;
      return d1.compareTo(d2);
    });

    _pendingTiles.addAll(newlyFound);
  }

  Future<void> _spawnTile(int tx, int ty, String terrain) async {
    final tileKey = '${tx}_${ty}';
    if (_activeTiles.contains(tileKey)) return;
    _activeTiles.add(tileKey);

    final rand = Random(seed + tx * 92821 + ty * 53987 + 1);

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) {
      return;
    }

    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final selected = _pickStaticByWeight(entries, rand);
    final tileSize = selected.tileSize ?? staticTileSize;
    final count = rand.nextInt(
      (selected.maxCount ?? maxCount) - (selected.minCount ?? minCount) + 1,
    ) + (selected.minCount ?? minCount);

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(
        tx * tileSize + offsetX,
        ty * tileSize + offsetY,
      );

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final sprite = await Sprite.load(selected.path);

      final sizeValue = (selected.minSize ?? minSize) +
          rand.nextDouble() *
              ((selected.maxSize ?? maxSize) - (selected.minSize ?? minSize));

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
      if (roll < cumulative) return entry;
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
