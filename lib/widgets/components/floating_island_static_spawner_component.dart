import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/static_sprite_entry.dart';
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
    this.staticTileSize = 128.0,
    this.seed = 8888,
    this.minCount = 1,
    this.maxCount = 2,
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

    if (_lastLogicalOffset != null && (_lastLogicalOffset! - offset).length < 1) {
      return;
    }

    _lastLogicalOffset = offset.clone();
    updateTileRendering(offset, viewSize);
  }

  static Map<String, List<StaticSpriteEntry>> _normalizeSpriteMap(
      Map<String, List<StaticSpriteEntry>> original) {
    const defaultType = 'default_static'; // ✅ 默认类型，保证所有 entry 都有 type

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

  /// 🌟立即强制刷新（跳过逻辑坐标检查）
  void forceRefresh() {
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    debugPrint(
        '[Spawner] forceRefresh called.\n'
            '  offset=$offset\n'
            '  viewSize=$viewSize\n'
            '  _lastLogicalOffset(before)=$_lastLogicalOffset'
    );
    _lastLogicalOffset = null; // 确保下一帧 update() 会刷新
    updateTileRendering(offset, viewSize);
    debugPrint(
        '[Spawner] forceRefresh completed.\n'
            '  _lastLogicalOffset(after)=$_lastLogicalOffset'
    );
  }

  /// 强制刷新后，手动同步逻辑坐标
  void syncLogicalOffset(Vector2 offset) {
    _lastLogicalOffset = offset.clone();
  }

  void updateTileRendering(Vector2 offset, Vector2 viewSize) {
    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    // buffer, 回收、生成等都挪进来
    final bufferExtent = viewSize * 1.25;
    final bufferTopLeft = offset - bufferExtent;
    final bufferBottomRight = offset + bufferExtent;

    // ✅ 清理超出buffer的tile key（这个没问题）
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

    // ✅ 修复关键点：复制一份 grid.children 列表，避免遍历时修改集合
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
        deco.removeFromParent(); // ✅ 安全了，已脱离原集合的迭代
      } else {
        deco.updateVisualPosition(offset);
        deco.priority = ((deco.worldPosition.y + 1e14) * 1000).toInt();
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

        // 获取该 tile 中预期生成的 type 列表
        final tileCenter = Vector2(
          tx * staticTileSize + staticTileSize / 2,
          ty * staticTileSize + staticTileSize / 2,
        );
        final terrain = getTerrainType(tileCenter);
        if (!allowedTerrains.contains(terrain)) continue;

        final expectedTypes = staticSpritesMap[terrain]?.map((e) => e.type).toSet() ?? {};

        // 🧠 是否已经存在目标类型的装饰物
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
            .any((c) {
          if (expectedTypes.isEmpty) return true; // 没指定类型，tile 只要有东西就跳过
          return expectedTypes.contains(c.type);  // 否则必须命中同类型
        });

        if (alreadyExists) {
          _activeTiles.add(tileKey);
          continue;
        }

        newlyFound.add(_PendingTile(tx, ty, terrain));
      }
    }

    // 按中心距离排序
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

    final tileSpawnChance = 0.5;
    if (rand.nextDouble() > tileSpawnChance) return;

    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final selected = _pickStaticByWeight(entries, rand);

    final count = (selected.minCount != null && selected.maxCount != null)
        ? rand.nextInt(selected.maxCount! - selected.minCount! + 1) + selected.minCount!
        : rand.nextInt(maxCount - minCount + 1) + minCount;

    final tileSize = staticTileSize;
    final sizeValue = selected.fixedSize ?? (minSize + rand.nextDouble() * (maxSize - minSize));

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(
        tx * tileSize + offsetX,
        ty * tileSize + offsetY,
      );

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final spritePath = FloatingStaticEventStateUtil.getEffectiveSpritePath(
        originalPath: selected.path,
        worldPosition: worldPos,
        type: selected.type,
      );

      final flameGame = grid.findGame();
      if (flameGame == null) {
        debugPrint('❌ 找不到 FlameGame 实例，贴图加载失败：$spritePath');
        return;
      }

      final sprite = await Sprite.load(spritePath);

      final deco = FloatingIslandStaticDecorationComponent(
        sprite: sprite,
        size: Vector2.all(sizeValue),
        worldPosition: worldPos,
        logicalOffset: currentOffset,
        spritePath: selected.path,
        anchor: Anchor.bottomCenter,
      )
        ..type = selected.type // ✅ 关键！设置 type 字段
        ..add(RectangleHitbox()..collisionType = CollisionType.passive);

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
