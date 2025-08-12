// 📂 lib/widgets/components/floating_island_static_spawner_component.dart
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

  /// 生成后回调（保持你原逻辑）
  final void Function(FloatingIslandStaticDecorationComponent deco, String terrainType)?
  onStaticComponentCreated;

  // —— 原有状态 —— //
  final List<_PendingTile> _pendingTiles = [];
  final Set<String> _activeTiles = {};
  Vector2? _lastLogicalOffset;

  // ===== 优先级：脏标记 + 低频移动重排 + 防抖 =====
  /// 地图移动时是否也按低频重排
  final bool updatePriorityOnMove;

  /// 重排频率（Hz），<=0 表示不做节流（不建议）
  final double priorityFps;

  /// 相机位移达到多少像素才认为“需要移动重排”
  final double priorityMoveThreshold;

  /// 新增：脏标记的防抖；有大量增删时，等这么久再排一次
  final double dirtyDebounceSec;

  bool _zOrderDirty = true;   // 有增删时置脏
  double _prioAcc = 0;        // 频率累计器（基于 priorityFps）
  double _dirtyAcc = 0;       // 脏标记防抖累计
  Vector2? _prioLastOffset;   // 上次用来判断移动的相机位置

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

    // ✅ 降频：默认 6 次/秒；移动阈值 12px；新增防抖 0.20s
    this.updatePriorityOnMove = true,
    this.priorityFps = 6.0,
    this.priorityMoveThreshold = 12.0,
    this.dirtyDebounceSec = 0.20,
  })  : allowedTerrains = allowedTerrains,
        staticSpritesMap = _normalizeSpriteMap(staticSpritesMap);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    updateTileRendering(offset, viewSize);

    // 初次进场做一次重排
    _zOrderDirty = true;
    _updatePrioritiesTick(0, offset);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offset = getLogicalOffset();
    final viewSize = getViewSize();

    // 小位移早退，但仍跑一次“节流重排 tick”
    if (_lastLogicalOffset != null && (_lastLogicalOffset! - offset).length < 1) {
      _updatePrioritiesTick(dt, offset);
      return;
    }

    _lastLogicalOffset = offset.clone();
    updateTileRendering(offset, viewSize);

    // 重排 tick（可能是脏标记触发，或低频移动触发）
    _updatePrioritiesTick(dt, offset);
  }

  static Map<String, List<StaticSpriteEntry>> _normalizeSpriteMap(
      Map<String, List<StaticSpriteEntry>> original,
      ) {
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

  // ==== 外部强刷 / 同步偏移 ====
  void forceRefresh() {
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    _lastLogicalOffset = null;
    updateTileRendering(offset, viewSize);
    _zOrderDirty = true; // 强刷后重排一次
  }

  void syncLogicalOffset(Vector2 offset) {
    _lastLogicalOffset = offset.clone();
  }

  // ==== 生成渲染 ====
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

    final decorations =
    grid.children.whereType<FloatingIslandStaticDecorationComponent>().toList();
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
        _zOrderDirty = true; // 有移除 → 置脏（但会被防抖合并）
      } else {
        deco.updateVisualPosition(offset);
      }
    }

    _collectPendingTiles(visibleTopLeft, visibleBottomRight);

    // 一帧全刷/保留你原逻辑（如需更丝滑，可改成分帧）
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

        final expectedTypes =
            staticSpritesMap[terrain]?.map((e) => e.type).toSet() ?? {};
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

  Future<void> _spawnTile(
      int tx,
      int ty,
      String terrain,
      Vector2 currentOffset,
      ) async {
    final tileKey = '${tx}_${ty}';
    if (_activeTiles.contains(tileKey)) return;
    _activeTiles.add(tileKey);

    final rand = Random(seed + tx * 92821 + ty * 53987 + 1);
    if (rand.nextDouble() > 0.5) return; // 保留你原来的概率策略

    final entries = staticSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    final selected = _pickStaticByWeight(entries, rand);

    // 宝箱生成判断（按 tileKey）
    if (selected.type == 'treasure_chest' &&
        await TreasureChestStorage.isOpenedTile(tileKey)) {
      return;
    }

    final count = (selected.minCount != null && selected.maxCount != null)
        ? rand.nextInt(selected.maxCount! - selected.minCount! + 1) +
        selected.minCount!
        : rand.nextInt(maxCount - minCount + 1) + minCount;

    final tileSize = staticTileSize;
    final sizeValue =
        selected.fixedSize ?? (minSize + rand.nextDouble() * (maxSize - minSize));

    final List<FloatingIslandStaticDecorationComponent> components = [];

    for (int i = 0; i < count; i++) {
      final offsetX = rand.nextDouble() * tileSize;
      final offsetY = rand.nextDouble() * tileSize;
      final worldPos = Vector2(tx * tileSize + offsetX, ty * tileSize + offsetY);

      if (!allowedTerrains.contains(getTerrainType(worldPos))) continue;

      final spritePath = await FloatingStaticEventStateUtil.getEffectiveSpritePath(
        originalPath: selected.path,
        worldPosition: worldPos,
        type: selected.type,
        tileKey: tileKey,
      );

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
        tileKey: tileKey,
        anchor: Anchor.bottomCenter,
      );

      // 仅当 type 非 null 时才添加碰撞盒
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

    if (components.isNotEmpty) {
      _zOrderDirty = true; // 有新增 → 置脏（会被防抖合并）
      _dirtyAcc = 0.0;     // 置脏后开始计时
    }
  }

  // ===== 低频 / 防抖重排 =====
  void _updatePrioritiesTick(double dt, Vector2 currentOffset) {
    // 频率累计（节流）
    if (priorityFps > 0) _prioAcc += dt;
    final step = (priorityFps > 0) ? (1.0 / priorityFps) : 0.0;
    final movedEnough = _prioLastOffset != null
        ? (_prioLastOffset! - currentOffset).length >= priorityMoveThreshold
        : true;

    // 1) 有脏标记 → 走防抖（合并本帧的批量增删）
    if (_zOrderDirty) {
      _dirtyAcc += dt;
      // 未到防抖时间就先不排
      if (_dirtyAcc < dirtyDebounceSec) return;
      // 到点了，且（若设置了节流）也到频率了 → 排一次
      if (priorityFps <= 0 || _prioAcc >= step) {
        _doSort(currentOffset);
      }
      return;
    }

    // 2) 没脏标记，仅因相机移动触发 → 按位移阈值 + 频率节流
    if (!updatePriorityOnMove) return;
    if (!movedEnough) return;
    if (priorityFps > 0 && _prioAcc < step) return;

    _doSort(currentOffset);
  }

  void _doSort(Vector2 currentOffset) {
    _updateDecorationPriorities();
    _zOrderDirty = false;
    _dirtyAcc = 0.0;
    _prioAcc = 0.0;
    _prioLastOffset = currentOffset.clone();
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
