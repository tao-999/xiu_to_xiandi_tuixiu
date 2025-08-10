import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/static_sprite_entry.dart';
import '../../services/treasure_chest_storage.dart';
import '../../utils/floating_static_event_state_util.dart';
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

  final List<_PendingTile> _pendingTiles = [];
  final Set<String> _activeTiles = {};
  Vector2? _lastLogicalOffset;

  FloatingIslandStaticSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required Set<String> allowedTerrains,
    required Map<String, List<StaticSpriteEntry>> staticSpritesMap,
    this.staticTileSize = 64.0,
    this.seed = 8888,
    this.minCount = 0,
    this.maxCount = 1,
    this.minSize = 16.0,
    this.maxSize = 48.0,
    this.onStaticComponentCreated,
  })  : allowedTerrains = allowedTerrains,
        staticSpritesMap = _normalizeSpriteMap(staticSpritesMap);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    updateTileRendering(offset, viewSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    if (_lastLogicalOffset != null && (_lastLogicalOffset! - offset).length < 1) return;
    _lastLogicalOffset = offset.clone();
    updateTileRendering(offset, viewSize);
    _updateDecorationPriorities(); // ✅ 自动调整层级
  }

  static Map<String, List<StaticSpriteEntry>> _normalizeSpriteMap(
      Map<String, List<StaticSpriteEntry>> original) {
    const defaultType = 'default_static';
    final result = <String, List<StaticSpriteEntry>>{};
    for (final entry in original.entries) {
      final terrain = entry.key;
      final list = entry.value;
      result[terrain] = list.map((e) {
        return e.copyWith(type: e.type ?? defaultType);
      }).toList();
    }
    return result;
  }

  void forceRefresh() {
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    _lastLogicalOffset = null;
    updateTileRendering(offset, viewSize);
  }

  void syncLogicalOffset(Vector2 offset) {
    _lastLogicalOffset = offset.clone();
  }

  void updateTileRendering(Vector2 offset, Vector2 viewSize) {
    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;
    final bufferExtent = viewSize * 1.25;
    final bufferTopLeft = offset - bufferExtent;
    final bufferBottomRight = offset + bufferExtent;

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

    final decorations = grid.children.whereType<FloatingIslandStaticDecorationComponent>().toList();
    for (final deco in decorations) {
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
      }
    }

    _collectPendingTiles(visibleTopLeft, visibleBottomRight);

    final tilesPerFrame = _pendingTiles.length;
    int spawned = 0;
    while (_pendingTiles.isNotEmpty && spawned < tilesPerFrame) {
      final tile = _pendingTiles.removeAt(0);
      _spawnTile(tile.tx, tile.ty, tile.terrain, offset);
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
        final tileCenter = Vector2(
          tx * staticTileSize + staticTileSize / 2,
          ty * staticTileSize + staticTileSize / 2,
        );
        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        final expectedTypes = staticSpritesMap[terrain]?.map((e) => e.type).toSet() ?? {};
        final alreadyExists = grid.children
            .whereType<FloatingIslandStaticDecorationComponent>()
            .where((c) {
          final pos = c.worldPosition;
          final sameTile = pos.x >= tx * staticTileSize &&
              pos.x < (tx + 1) * staticTileSize &&
              pos.y >= ty * staticTileSize &&
              pos.y < (ty + 1) * staticTileSize;
          return sameTile;
        })
            .any((c) => expectedTypes.isEmpty || expectedTypes.contains(c.type));

        if (alreadyExists) {
          _activeTiles.add(tileKey);
          continue;
        }

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

  Future<void> _spawnTile(int tx, int ty, String terrain, Vector2 currentOffset) async {
    final tileKey = '${tx}_${ty}';
    if (_activeTiles.contains(tileKey)) return;
    _activeTiles.add(tileKey);

    final rand = Random(seed + tx * 92821 + ty * 53987 + 1);
    if (rand.nextDouble() > 0.5) return;

    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final selected = _pickStaticByWeight(entries, rand);

    // ✅ 宝箱生成判断（按 tileKey）→ await！
    if (selected.type == 'treasure_chest' &&
        await TreasureChestStorage.isOpenedTile(tileKey)) {
      print('🚫 [Spawner] 已开启宝箱，跳过生成 tileKey=$tileKey');
      return;
    }

    final count = (selected.minCount != null && selected.maxCount != null)
        ? rand.nextInt(selected.maxCount! - selected.minCount! + 1) + selected.minCount!
        : rand.nextInt(maxCount - minCount + 1) + minCount;

    final tileSize = staticTileSize;
    final sizeValue = selected.fixedSize ?? (minSize + rand.nextDouble() * (maxSize - minSize));

    final List<FloatingIslandStaticDecorationComponent> components = [];

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(tx * tileSize + offsetX, ty * tileSize + offsetY);

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      // ✅ 异步判断贴图（比如宝箱开没开）
      final spritePath = await FloatingStaticEventStateUtil.getEffectiveSpritePath(
        originalPath: selected.path,
        worldPosition: worldPos,
        type: selected.type,
        tileKey: tileKey,
      );

      final flameGame = grid.findGame();
      if (flameGame == null) return;

      final sprite = await Sprite.load(spritePath);
      final imageSize = sprite.srcSize;
      final double scale = sizeValue / imageSize.x;
      final Vector2 fixedSize = imageSize * scale;

      final deco = FloatingIslandStaticDecorationComponent(
        sprite: sprite,
        size: fixedSize,
        worldPosition: worldPos,
        logicalOffset: currentOffset,
        spritePath: selected.path,
        type: selected.type,
        tileKey: tileKey, // ✅ tileKey 保留
        anchor: Anchor.bottomCenter,
      );
      if (selected.type != null) {
        deco.add(RectangleHitbox()..collisionType = CollisionType.passive);
      }

      if (selected.priority != null) {
        deco.priority = selected.priority!;
        deco.ignoreAutoPriority = true;
      }

      components.add(deco);
    }

    for (final deco in components) {
      onStaticComponentCreated?.call(deco, terrain);
      grid.add(deco);
    }
  }

  void _updateDecorationPriorities() {
    final decorations = grid.children
        .whereType<FloatingIslandStaticDecorationComponent>()
        .where((c) => !c.ignoreAutoPriority)
        .toList();

    decorations.sort((a, b) => a.worldPosition.y.compareTo(b.worldPosition.y));

    for (int i = 0; i < decorations.length; i++) {
      decorations[i].priority = i + 1;
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
