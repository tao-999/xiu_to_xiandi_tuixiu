// 📂 lib/widgets/components/floating_island_static_spawner_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/static_sprite_entry.dart';
import '../../services/treasure_chest_storage.dart';
import '../../utils/floating_static_event_state_util.dart';
import 'floating_island_static_decoration_component.dart';

/// —— 性能要点 ——
/// 1) 地形 -> 位掩码，避免热区字符串比较
/// 2) tile -> 组件 列表的 O(1) 索引，避免每帧 whereType 扫全树
/// 3) Sprite 缓存（按有效路径），避免重复 load
/// 4) 生成 & 移除时维护索引；排序节流+防抖保留
class FloatingIslandStaticSpawnerComponent extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;

  /// 返回地形名（你原逻辑保留）；本类内部会映射为 int 位掩码
  final String Function(Vector2) getTerrainType;

  /// 允许的地形（外部仍用字符串传入）
  final Set<String> allowedTerrains;

  /// 每个地形对应的静态精灵候选（外部仍传字符串键）
  final Map<String, List<StaticSpriteEntry>> staticSpritesMap;

  final double staticTileSize;
  final int seed;
  final int minCount;
  final int maxCount;
  final double minSize;
  final double maxSize;

  final void Function(FloatingIslandStaticDecorationComponent deco, String terrainType)?
  onStaticComponentCreated;

  // —— 状态 —— //
  final List<_PendingTile> _pendingTiles = [];
  final Set<String> _activeTiles = {};
  Vector2? _lastLogicalOffset;

  // —— 索引：tileKey -> 装饰组件列表（O(1) 查同 tile）—— //
  final Map<int, List<FloatingIslandStaticDecorationComponent>> _byTile = {};

  // —— 贴图缓存（按“有效路径”，兼容状态切换贴图）—— //
  final Map<String, Sprite> _spriteCache = {};

  // —— 地形名 → int 映射；以及允许掩码 —— //
  late final Map<String, int> _terrainId;
  late final int _allowedMask;

  // —— 优先级节流/防抖 —— //
  final bool updatePriorityOnMove;
  final double priorityFps;
  final double priorityMoveThreshold;
  final double dirtyDebounceSec;

  bool _zOrderDirty = true;
  double _prioAcc = 0;
  double _dirtyAcc = 0;
  Vector2? _prioLastOffset;

  FloatingIslandStaticSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    required Map<String, List<StaticSpriteEntry>> staticSpritesMap,
    this.staticTileSize = 64.0,
    this.seed = 8888,
    this.minCount = 0,
    this.maxCount = 1,
    this.minSize = 16.0,
    this.maxSize = 48.0,
    this.onStaticComponentCreated,

    // ✅ 降频：默认 6Hz；位移阈值 12px；防抖 0.20s
    this.updatePriorityOnMove = true,
    this.priorityFps = 6.0,
    this.priorityMoveThreshold = 12.0,
    this.dirtyDebounceSec = 0.20,
  }) : staticSpritesMap = _normalizeSpriteMap(staticSpritesMap);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) 地形名 → 连续 int，下沉热路径成本
    _terrainId = _makeTerrainIdMap(staticSpritesMap.keys);
    _allowedMask = _maskFromAllowed(allowedTerrains, _terrainId);

    // 2) 首帧把已有的装饰物构建索引（如果有）
    _rebuildTileIndexFromGrid();

    // 3) 首帧生成/更新 & 初次重排
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    updateTileRendering(offset, viewSize);
    _zOrderDirty = true;
    _updatePrioritiesTick(0, offset);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offset = getLogicalOffset();
    final viewSize = getViewSize();

    // 小位移早退，但跑一次重排 tick
    if (_lastLogicalOffset != null &&
        (_lastLogicalOffset! - offset).length < 1) {
      _updatePrioritiesTick(dt, offset);
      return;
    }

    _lastLogicalOffset = offset.clone();
    updateTileRendering(offset, viewSize);
    _updatePrioritiesTick(dt, offset);
  }

  // ==== 工具：地形表归一化（保持你原有 default type 逻辑） ==== //
  static Map<String, List<StaticSpriteEntry>> _normalizeSpriteMap(
      Map<String, List<StaticSpriteEntry>> original) {
    const defaultType = 'default_static';
    final result = <String, List<StaticSpriteEntry>>{};
    for (final entry in original.entries) {
      final terrain = entry.key;
      final list = entry.value;
      result[terrain] = list.map((e) => e.copyWith(type: e.type ?? defaultType)).toList();
    }
    return result;
  }

  // ==== 外部强刷 / 同步偏移 ==== //
  void forceRefresh() {
    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    _lastLogicalOffset = null;
    updateTileRendering(offset, viewSize);
    _zOrderDirty = true;
  }

  void syncLogicalOffset(Vector2 offset) {
    _lastLogicalOffset = offset.clone();
  }

  // ==== 生成 & 渲染 ==== //
  void updateTileRendering(Vector2 offset, Vector2 viewSize) {
    final visibleTopLeft = offset - viewSize / 2;
    final visibleBottomRight = visibleTopLeft + viewSize;

    // 视野缓冲区：减少频繁增删
    final bufferExtent = viewSize * 1.25;
    final bufferTopLeft = offset - bufferExtent;
    final bufferBottomRight = offset + bufferExtent;

    // 1) 回收缓冲区外的现有组件（同时维护索引）
    final decorations =
    grid.children.whereType<FloatingIslandStaticDecorationComponent>().toList();
    for (final deco in decorations) {
      final pos = deco.worldPosition;
      final out =
          pos.x < bufferTopLeft.x ||
              pos.x > bufferBottomRight.x ||
              pos.y < bufferTopLeft.y ||
              pos.y > bufferBottomRight.y;

      if (out) {
        final tx = (pos.x / staticTileSize).floor();
        final ty = (pos.y / staticTileSize).floor();
        _activeTiles.remove('${tx}_${ty}');
        _indexOnRemove(deco, tx, ty); // ✅ 索引维护
        deco.removeFromParent();
        _zOrderDirty = true;
      } else {
        deco.updateVisualPosition(offset);
      }
    }

    // 2) 收集“可见范围内、当前 tile 尚未放置”的 tile
    _collectPendingTiles(visibleTopLeft, visibleBottomRight);

    // 3) 本帧把待生成的全部刷完（如需更丝滑可分帧）
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

        final terrainStr = getTerrainType(tileCenter);
        final terrainInt = _terrainId[terrainStr];
        if (terrainInt == null) continue;
        if (!_maskHas(_allowedMask, terrainInt)) continue;

        // ✅ O(1) 判断该 tile 是否已有装饰（不再扫全 children）
        final existsList = _byTile[_keyOf(tx, ty)];
        final expectedTypes =
            (staticSpritesMap[terrainStr]?.map((e) => e.type).toSet()) ?? {};
        final alreadyExists = (existsList != null) &&
            existsList.any((c) => expectedTypes.isEmpty || expectedTypes.contains(c.type));

        if (alreadyExists) {
          _activeTiles.add(tileKey);
          continue;
        }

        newlyFound.add(_PendingTile(tx, ty, terrainStr));
      }
    }

    // ✅ 由近到远生成，减少跳帧感
    newlyFound.sort((a, b) {
      final d1 = (a.center(staticTileSize) - center).length2;
      final d2 = (b.center(staticTileSize) - center).length2;
      return d1.compareTo(d2);
    });

    _pendingTiles.addAll(newlyFound);
  }

  Future<void> _spawnTile(
      int tx,
      int ty,
      String terrainStr,
      Vector2 currentOffset,
      ) async {
    final tileKey = '${tx}_${ty}';
    if (_activeTiles.contains(tileKey)) return;
    _activeTiles.add(tileKey);

    final rand = Random(seed + tx * 92821 + ty * 53987 + 1);
    if (rand.nextDouble() > 0.5) return; // 保留你的概率策略

    final entries = staticSpritesMap[terrainStr] ?? const <StaticSpriteEntry>[];
    if (entries.isEmpty) return;

    final selected = _pickStaticByWeight(entries, rand);

    // ✅ 宝箱去重（tile 粒度）
    if (selected.type == 'treasure_chest' &&
        await TreasureChestStorage.isOpenedTile(tileKey)) {
      return;
    }

    final cnt = (selected.minCount != null && selected.maxCount != null)
        ? rand.nextInt(selected.maxCount! - selected.minCount! + 1) + selected.minCount!
        : rand.nextInt(maxCount - minCount + 1) + minCount;

    final t = staticTileSize;

    for (int i = 0; i < cnt; i++) {
      final ox = rand.nextDouble() * t;
      final oy = rand.nextDouble() * t;
      final worldPos = Vector2(tx * t + ox, ty * t + oy);

      // 二次地形确认（边界随机偏移时避免跨层）
      final terrainNow = getTerrainType(worldPos);
      if (terrainNow != terrainStr) continue;

      // ✅ 根据“事件状态”拿到真正要用的贴图路径（一次缓存）
      final effectivePath = await FloatingStaticEventStateUtil.getEffectiveSpritePath(
        originalPath: selected.path,
        worldPosition: worldPos,
        type: selected.type,
        tileKey: tileKey,
      );
      final sprite = await _getSpriteCached(effectivePath);

      final imageSize = sprite.srcSize;
      final double size =
          selected.fixedSize ?? (minSize + rand.nextDouble() * (maxSize - minSize));
      final double scale = size / imageSize.x;
      final Vector2 fixedSize = imageSize * scale;

      final deco = FloatingIslandStaticDecorationComponent(
        sprite: sprite,
        size: fixedSize,
        worldPosition: worldPos,
        logicalOffset: currentOffset,
        spritePath: selected.path, // 保留原始路径做业务 key
        type: selected.type,
        tileKey: tileKey,
        anchor: Anchor.bottomCenter,
      );

      // 仅当 type 非 null 时才添加碰撞盒（保持你原逻辑）
      if (selected.type != null) {
        deco.add(RectangleHitbox()..collisionType = CollisionType.passive);
      }

      if (selected.priority != null) {
        deco.priority = selected.priority!;
        deco.ignoreAutoPriority = true;
      }

      onStaticComponentCreated?.call(deco, terrainStr);
      grid.add(deco);
      _indexOnAdd(deco, tx, ty); // ✅ 建立 O(1) 索引
    }

    _zOrderDirty = true; // 有新增 → 置脏
    _dirtyAcc = 0.0;
  }

  // ====== 排序节流 / 防抖 ====== //
  void _updatePrioritiesTick(double dt, Vector2 currentOffset) {
    if (priorityFps > 0) _prioAcc += dt;
    final step = (priorityFps > 0) ? (1.0 / priorityFps) : 0.0;
    final movedEnough = _prioLastOffset != null
        ? (_prioLastOffset! - currentOffset).length >= priorityMoveThreshold
        : true;

    // 1) 脏标记 → 防抖合并
    if (_zOrderDirty) {
      _dirtyAcc += dt;
      if (_dirtyAcc < dirtyDebounceSec) return;
      if (priorityFps <= 0 || _prioAcc >= step) {
        _doSort(currentOffset);
      }
      return;
    }

    // 2) 仅因移动触发
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
    final list = grid.children
        .whereType<FloatingIslandStaticDecorationComponent>()
        .where((c) => !c.ignoreAutoPriority)
        .toList();

    // 从下到上，y 小在后，避免穿插
    list.sort((a, b) => a.worldPosition.y.compareTo(b.worldPosition.y));
    for (int i = 0; i < list.length; i++) {
      list[i].priority = i + 1;
    }
  }

  // ====== 工具：权重抽样 / 贴图缓存 / 索引 / 地形位掩码 ====== //
  StaticSpriteEntry _pickStaticByWeight(List<StaticSpriteEntry> entries, Random r) {
    final total = entries.fold<int>(0, (s, e) => s + e.weight);
    int roll = r.nextInt(total), acc = 0;
    for (final e in entries) {
      acc += e.weight;
      if (roll < acc) return e;
    }
    return entries.first;
  }

  Future<Sprite> _getSpriteCached(String path) async {
    final cached = _spriteCache[path];
    if (cached != null) return cached;
    final s = await Sprite.load(path);
    _spriteCache[path] = s;
    return s;
  }

  // tile 键（整数 O(1)）
  int _keyOf(int tx, int ty) => (tx << 16) ^ (ty & 0xFFFF);

  void _indexOnAdd(FloatingIslandStaticDecorationComponent d, int tx, int ty) {
    final k = _keyOf(tx, ty);
    (_byTile[k] ??= <FloatingIslandStaticDecorationComponent>[]).add(d);
  }

  void _indexOnRemove(FloatingIslandStaticDecorationComponent d, int tx, int ty) {
    final k = _keyOf(tx, ty);
    final list = _byTile[k];
    if (list == null) return;
    list.remove(d);
    if (list.isEmpty) _byTile.remove(k);
  }

  void _rebuildTileIndexFromGrid() {
    _byTile.clear();
    final items = grid.children.whereType<FloatingIslandStaticDecorationComponent>();
    for (final d in items) {
      final tx = (d.worldPosition.x / staticTileSize).floor();
      final ty = (d.worldPosition.y / staticTileSize).floor();
      _indexOnAdd(d, tx, ty);
    }
  }

  Map<String, int> _makeTerrainIdMap(Iterable<String> names) {
    final map = <String, int>{};
    int id = 0;
    for (final n in names) {
      map[n] = id++;
    }
    return map;
  }

  int _maskFromAllowed(Set<String> allowed, Map<String, int> idMap) {
    int m = 0;
    for (final s in allowed) {
      final id = idMap[s];
      if (id != null) m |= (1 << id);
    }
    return m;
  }

  bool _maskHas(int mask, int id) => (mask & (1 << id)) != 0;
}

class _PendingTile {
  final int tx;
  final int ty;
  final String terrain;
  _PendingTile(this.tx, this.ty, this.terrain);
  Vector2 center(double tileSize) => Vector2(
    tx * tileSize + tileSize / 2,
    ty * tileSize + tileSize / 2,
  );
}
