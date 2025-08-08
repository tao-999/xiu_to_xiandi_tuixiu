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
      final tile = _pendingTiles.removeAt(0);
      _spawnDynamicComponentsForTile(tile.tx, tile.ty, tile.terrain);
      spawned++;
    }
  }

  /// 🌍 查找附近合法地形坐标
  Vector2? findNearbyValidTile({
    required Vector2 center,
    double minRadius = 100,
    double maxRadius = 500,
    int maxAttempts = 30,
  }) {
    final rand = Random();
    for (int i = 0; i < maxAttempts; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = minRadius + rand.nextDouble() * (maxRadius - minRadius);
      final offset = Vector2(cos(angle) * radius, sin(angle) * radius);
      final candidate = center + offset;
      if (allowedTerrains.contains(getTerrainType(candidate))) {
        return candidate;
      }
    }
    print('❌ [Spawner] 附近找不到合法地形（min=$minRadius, max=$maxRadius）');
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
      final mover = await _createMover(rand, selected, tx, ty, i, type, terrain, tileKey);
      if (mover != null) {
        print('✨ 生成 Mover: type=$type tileKey=$tileKey worldPos=${mover.position}');
        onDynamicComponentCreated?.call(mover, terrain);
        mover.onRemoveCallback = () {
          print('🗑️ 移除 Mover: type=$type tileKey=$tileKey');
          _loadedDynamicTiles.remove(tileKey);
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
    final worldPos = Vector2(tx * tileSize + rand.nextDouble() * tileSize, ty * tileSize + rand.nextDouble() * tileSize);
    if (!allowedTerrains.contains(getTerrainType(worldPos))) return null;

    final sprite = _spriteCache[selected.path]!;
    final originalSize = sprite.srcSize;

    final size = selected.desiredWidth != null
        ? originalSize * (selected.desiredWidth! / originalSize.x)
        : originalSize * ((selected.minSize ?? minDynamicObjectSize) +
        rand.nextDouble() * ((selected.maxSize ?? maxDynamicObjectSize) - (selected.minSize ?? minDynamicObjectSize))) /
        originalSize.x;

    final speed = (selected.minSpeed ?? minSpeed) + rand.nextDouble() * ((selected.maxSpeed ?? maxSpeed) - (selected.minSpeed ?? minSpeed));

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
        ? NameGenerator.generateWithSeed(Random(seed + '${tx}_${ty}_${index}_${selected.path}_$type'.hashCode), isMale: true)
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
    if (type.startsWith('danyao_')) return await CollectedPillStorage.isCollected(tileKey);
    if (type == 'gongfa_1') return await GongfaCollectedStorage.isCollected(tileKey);
    if (type == 'charm_1') return await FateRecruitCharmStorage.isCollected(tileKey);
    if (type == 'recruit_ticket') return await RecruitTicketStorage.isCollected(tileKey);
    if (type == 'xiancao') return await CollectedXiancaoStorage.isCollected(tileKey);
    if (type == 'favorability') return await CollectedFavorabilityStorage.isCollected(tileKey);
    if (type == 'lingshi') return await CollectedLingShiStorage.isCollected(tileKey);
    if (type == 'jinkuang') return await CollectedJinkuangStorage.isCollected(tileKey);
    return false;
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
