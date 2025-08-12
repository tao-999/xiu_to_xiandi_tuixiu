// 📂 lib/widgets/components/floating_island_dynamic_spawner_component.dart
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/services/collected_favorability_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/collected_jinkuang_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/collected_lingshi_storage.dart';
import '../../services/collected_pill_storage.dart';
import '../../services/collected_xiancao_storage.dart';
import '../../services/dead_boss_storage.dart';
import '../../services/fate_recruit_charm_storage.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../services/recruit_ticket_storage.dart';
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

  // ====== 🔧 新增：运行期索引 & GC/限流配置 ======
  // tileKey -> movers
  final Map<String, List<FloatingIslandDynamicMoverComponent>> _tileActors = {};
  // "tx_ty" -> {tileKey, ...}
  final Map<String, Set<String>> _tileCoordToKeys = {};

  double _gcTicker = 0.0;

  static const double _gcIntervalSec   = 0.6;  // 定期离屏回收周期
  static const int    _maxActiveMovers = 260;  // 全局活跃上限
  static const int    _maxPerTile      = 6;    // 单 tile 活跃上限
  static const int    _unloadPadTiles  = 3;    // 卸载缓冲（视野外 N 个 tile）

  FloatingIslandDynamicSpawnerComponent({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    required this.dynamicSpritesMap,
    this.dynamicTileSize = 64.0,
    this.seed = 8888,
    this.minDynamicObjectsPerTile = 0,
    this.maxDynamicObjectsPerTile = 1,
    this.minDynamicObjectSize = 32.0,
    this.maxDynamicObjectSize = 64.0,
    this.minSpeed = 10.0,
    this.maxSpeed = 50.0,
    this.onDynamicComponentCreated,
    this.noiseMapGenerator,
  });

  // 🧰 小工具
  String _coordKey(int tx, int ty) => '${tx}_${ty}';
  int _countActiveMovers() =>
      _tileActors.values.fold(0, (s, lst) => s + lst.length);

  /// 🧠 Sprite 资源预加载
  @override
  Future<void> onLoad() async {
    for (final entries in dynamicSpritesMap.values) {
      for (final entry in entries) {
        _spriteCache[entry.path] ??= await Sprite.load(entry.path);
      }
    }
  }

  /// 🎯 每帧更新
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
      // ✋ 全局限流：达上限则暂停生成
      if (_countActiveMovers() >= _maxActiveMovers) break;

      final tile = _pendingTiles.removeAt(0);
      _spawnDynamicComponentsForTile(tile.tx, tile.ty, tile.terrain);
      spawned++;
    }

    // 🧹 定期离屏回收（清理视野 ±N tiles 之外的 mover）
    _gcTicker += dt;
    if (_gcTicker >= _gcIntervalSec) {
      _gcTicker = 0;
      _despawnFarTiles(visibleTopLeft, visibleBottomRight);
    }
  }

  /// 🌍 查找附近合法地形坐标（多点采样+安全边距+可选边界）
  Vector2? findNearbyValidTile({
    required Vector2 center,
    double minRadius = 100,
    double maxRadius = 500,
    int maxAttempts = 30,
    Rect? preferredWithin,
    double safeMargin = 16.0, // ✅ 安全边距（像素）
  }) {
    // 统一地形判定口径（使用噪声生成器优先）
    String classify(Vector2 p) {
      if (noiseMapGenerator != null) {
        return noiseMapGenerator!.getTerrainTypeAtPosition(p);
      }
      return getTerrainType(p);
    }

    bool isRobustAllowed(Vector2 p) {
      // 十字+对角 9 点采样，确保不是贴边
      const offsets = [
        Offset(0, 0),
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
        Offset(1, 1),
        Offset(1, -1),
        Offset(-1, 1),
        Offset(-1, -1),
      ];
      int ok = 0;
      for (final o in offsets) {
        final q = Vector2(p.x + o.dx * safeMargin, p.y + o.dy * safeMargin);
        if (allowedTerrains.contains(classify(q))) ok++;
      }
      // 9 点里至少 7 点合法，才算“稳固”
      return ok >= 7;
    }

    Vector2 clampWithin(Vector2 p) {
      if (preferredWithin == null) return p;

      final rect = preferredWithin!;
      final w = rect.width;
      final h = rect.height;

      if (w <= 0 || h <= 0) return p;

      double mx = min(safeMargin, w / 2 - 0.5);
      double my = min(safeMargin, h / 2 - 0.5);
      if (mx < 0) mx = 0;
      if (my < 0) my = 0;

      double left = rect.left + mx;
      double right = rect.right - mx;
      if (left > right) {
        final mid = (rect.left + rect.right) / 2;
        left = right = mid;
      }

      double top = rect.top + my;
      double bottom = rect.bottom - my;
      if (top > bottom) {
        final mid = (rect.top + rect.bottom) / 2;
        top = bottom = mid;
      }

      final x = p.x.clamp(left, right);
      final y = p.y.clamp(top, bottom);
      return Vector2(x.toDouble(), y.toDouble());
    }

    final rand = Random();
    // 黄金角+扩展环均匀撒点
    const golden = 2.39996322972865332;
    final rings = max(4, (maxAttempts / 8).floor());
    final basePerRing = max(8, (maxAttempts / rings).ceil());

    for (int r = 0; r < rings; r++) {
      final t = rings == 1 ? 1.0 : r / (rings - 1);
      final radius = lerpDouble(minRadius, maxRadius, t)!;

      final samples = basePerRing + r * 2;
      for (int i = 0; i < samples; i++) {
        final angle = i * golden + r * 0.31 + rand.nextDouble() * 0.05; // 微扰
        final candidate = Vector2(
          center.x + cos(angle) * radius,
          center.y + sin(angle) * radius,
        );
        final q = clampWithin(candidate);

        if (isRobustAllowed(q)) {
          return q;
        }
      }
    }

    print('❌ [Spawner] 附近找不到“稳固”的合法地形（min=$minRadius, max=$maxRadius, margin=$safeMargin）');
    return null;
  }

  /// 🧱 视野内收集待处理 tile
  void _collectPendingTiles(Vector2 topLeft, Vector2 bottomRight) {
    final dStartX = (topLeft.x / dynamicTileSize).floor();
    final dStartY = (topLeft.y / dynamicTileSize).floor();
    final dEndX = (bottomRight.x / dynamicTileSize).ceil();
    final dEndY = (bottomRight.y / dynamicTileSize).ceil();
    final center = getLogicalOffset();
    final List<_PendingTile> newlyFound = [];

    for (int tx = dStartX; tx < dEndX; tx++) {
      for (int ty = dStartY; ty < dEndY; ty++) {
        final centerPos = Vector2(
          tx * dynamicTileSize + dynamicTileSize / 2,
          ty * dynamicTileSize + dynamicTileSize / 2,
        );
        final terrain = getTerrainType(centerPos);
        if (!allowedTerrains.contains(terrain)) continue;

        final types = dynamicSpritesMap[terrain]?.map((e) => e.type ?? 'null').toSet() ?? {'null'};
        for (final type in types) {
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

  /// 🧬 核心组件生成逻辑
  Future<void> _spawnDynamicComponentsForTile(int tx, int ty, String terrain) async {
    final entries = dynamicSpritesMap[terrain] ?? [];
    if (entries.isEmpty) return;

    // 单 tile 限流（横跨所有 type 的活跃总数）
    final coordKey = _coordKey(tx, ty);
    final activeKeys = _tileCoordToKeys[coordKey];
    final activeCount = activeKeys == null
        ? 0
        : activeKeys.fold<int>(0, (s, k) => s + (_tileActors[k]?.length ?? 0));
    if (activeCount >= _maxPerTile) return;

    final rand = Random(seed + tx * 92821 + ty * 53987 + 2);
    if (rand.nextDouble() > 0.5) return;

    final selected = _pickDynamicByWeight(entries, rand);
    final type = selected.type ?? 'null';
    final tileKey = '${tx}_${ty}_$type';

    if (await DeadBossStorage.isDead(tileKey)) return;
    if (await _shouldSkipByCollection(type, tileKey)) return;

    final minCount = selected.minCount ?? minDynamicObjectsPerTile;
    final maxCount = selected.maxCount ?? maxDynamicObjectsPerTile;
    final tileSize = selected.tileSize ?? dynamicTileSize;
    final count = rand.nextInt(maxCount - minCount + 1) + minCount;

    for (int i = 0; i < count; i++) {
      // ✋ 全局限流：动态检查
      if (_countActiveMovers() >= _maxActiveMovers) break;

      final mover = await _createMover(rand, selected, tx, ty, i, type, terrain, tileKey);
      if (mover != null) {
        // 登记：tileKey -> list
        _tileActors.putIfAbsent(tileKey, () => <FloatingIslandDynamicMoverComponent>[]);
        _tileActors[tileKey]!.add(mover);

        // 登记：(tx_ty) -> {tileKey}
        _tileCoordToKeys.putIfAbsent(coordKey, () => <String>{}).add(tileKey);

        print('✨ 生成 Mover: type=$type tileKey=$tileKey worldPos=${mover.position}');
        onDynamicComponentCreated?.call(mover, terrain);

        // 统一清理挂钩：remove 时同步回收索引 & 允许重刷
        final prevOnRemove = mover.onRemoveCallback;
        mover.onRemoveCallback = () {
          // 先调原回调（若有）
          try { prevOnRemove?.call(); } catch (_) {}

          // 再做索引清理
          final list = _tileActors[tileKey];
          list?.remove(mover);
          if (list != null && list.isEmpty) {
            _tileActors.remove(tileKey);
            _loadedDynamicTiles.remove(tileKey); // 允许回头再生
            final set = _tileCoordToKeys[coordKey];
            set?.remove(tileKey);
            if (set != null && set.isEmpty) _tileCoordToKeys.remove(coordKey);
          }

          print('🗑️ 移除 Mover: type=$type tileKey=$tileKey');
        };

        grid.add(mover);
      }
    }
  }

  /// ⚙️ 创建单个组件
  Future<FloatingIslandDynamicMoverComponent?> _createMover(
      Random rand,
      DynamicSpriteEntry selected,
      int tx,
      int ty,
      int index,
      String type,
      String terrain,
      String tileKey,
      ) async {
    final tileSize = selected.tileSize ?? dynamicTileSize;
    final worldPos = Vector2(
      tx * tileSize + rand.nextDouble() * tileSize,
      ty * tileSize + rand.nextDouble() * tileSize,
    );
    if (!allowedTerrains.contains(getTerrainType(worldPos))) return null;

    final sprite = _spriteCache[selected.path]!;
    final originalSize = sprite.srcSize;

    final size = selected.desiredWidth != null
        ? originalSize * (selected.desiredWidth! / originalSize.x)
        : originalSize *
        ((selected.minSize ?? minDynamicObjectSize) +
            rand.nextDouble() *
                ((selected.maxSize ?? maxDynamicObjectSize) -
                    (selected.minSize ?? minDynamicObjectSize))) /
        originalSize.x;

    final speed = (selected.minSpeed ?? minSpeed) +
        rand.nextDouble() * ((selected.maxSpeed ?? maxSpeed) - (selected.minSpeed ?? minSpeed));

    final bounds = noiseMapGenerator != null
        ? TerrainUtils.floodFillBoundingBox(
      start: worldPos,
      terrainType: terrain,
      getTerrainType: (pos) => noiseMapGenerator!.getTerrainTypeAtPosition(pos),
      sampleStep: 32.0,
      maxSteps: 2000,
    )
        : Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);

    final label = selected.generateRandomLabel == true
        ? NameGenerator.generateWithSeed(
      Random(seed + '${tx}_${ty}_${index}_${selected.path}_$type'.hashCode),
      isMale: true,
    )
        : selected.labelText;

    final dist = worldPos.length;
    final hp = selected.hp != null ? selected.hp! + dist / 10 : null;
    final atk = selected.atk != null ? selected.atk! + dist / 50 : null;
    final def = selected.def != null ? selected.def! + dist / 80 : null;

    return FloatingIslandDynamicMoverComponent(
      spawner: this,
      dynamicTileSize: dynamicTileSize,
      sprite: sprite,
      position: worldPos,
      movementBounds: bounds,
      speed: speed,
      size: size,
      spritePath: selected.path,
      defaultFacingRight: selected.defaultFacingRight,
      minDistance: selected.minDistance ?? 500.0,
      maxDistance: selected.maxDistance ?? 2000.0,
      labelText: label,
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
  }

  /// 🎲 权重随机选择
  DynamicSpriteEntry _pickDynamicByWeight(List<DynamicSpriteEntry> entries, Random rand) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.weight);
    int roll = rand.nextInt(total);
    int acc = 0;
    for (final e in entries) {
      acc += e.weight;
      if (roll < acc) return e;
    }
    return entries.first;
  }

  /// ✅ 资源判重封装（更清晰）
  Future<bool> _shouldSkipByCollection(String type, String tileKey) async {
    if (type == 'danyao') return await CollectedPillStorage.isCollected(tileKey);
    if (type == 'gongfa_1') return await GongfaCollectedStorage.isCollected(tileKey);
    if (type == 'charm_1') return await FateRecruitCharmStorage.isCollected(tileKey);
    if (type == 'recruit_ticket') return await RecruitTicketStorage.isCollected(tileKey);
    if (type == 'xiancao') return await CollectedXiancaoStorage.isCollected(tileKey);
    if (type == 'favorability') return await CollectedFavorabilityStorage.isCollected(tileKey);
    if (type == 'lingshi') return await CollectedLingShiStorage.isCollected(tileKey);
    if (type == 'jinkuang') return await CollectedJinkuangStorage.isCollected(tileKey);
    return false;
  }

  /// 🧹 卸载视野外的 tile 上的 movers
  void _despawnFarTiles(Vector2 topLeft, Vector2 bottomRight) {
    // 当前可见 tile 范围
    final minTx = (topLeft.x / dynamicTileSize).floor();
    final minTy = (topLeft.y / dynamicTileSize).floor();
    final maxTx = (bottomRight.x / dynamicTileSize).ceil();
    final maxTy = (bottomRight.y / dynamicTileSize).ceil();

    // 保留范围（加缓冲）
    final keepMinTx = minTx - _unloadPadTiles;
    final keepMinTy = minTy - _unloadPadTiles;
    final keepMaxTx = maxTx + _unloadPadTiles;
    final keepMaxTy = maxTy + _unloadPadTiles;

    // 找出需要卸载的 (tx_ty)
    final toDropCoords = <String>[];
    for (final ck in _tileCoordToKeys.keys) {
      final sp = ck.split('_');
      if (sp.length != 2) continue;
      final tx = int.tryParse(sp[0]) ?? 0;
      final ty = int.tryParse(sp[1]) ?? 0;
      final outside = tx < keepMinTx || tx > keepMaxTx || ty < keepMinTy || ty > keepMaxTy;
      if (outside) toDropCoords.add(ck);
    }

    if (toDropCoords.isEmpty) return;

    // 卸载这些 tile 上的所有 movers（触发 onRemoveCallback 自动清索引）
    for (final ck in toDropCoords) {
      final keys = _tileCoordToKeys[ck];
      if (keys == null) continue;
      final listKeys = List<String>.from(keys);
      for (final tileKey in listKeys) {
        final lst = _tileActors[tileKey];
        if (lst == null) continue;

        final movers = List<FloatingIslandDynamicMoverComponent>.from(lst);
        for (final m in movers) {
          m.removeFromParent();
        }
      }
    }
  }
}

/// 🧱 内部 tile 定义类
class _PendingTile {
  final int tx;
  final int ty;
  final String terrain;

  _PendingTile(this.tx, this.ty, this.terrain);

  Vector2 center(double tileSize) {
    return Vector2(tx * tileSize + tileSize / 2, ty * tileSize + tileSize / 2);
  }
}
