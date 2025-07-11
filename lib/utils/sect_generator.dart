import 'dart:math';

/// 用于从封闭区域中随机选宗门位置
class SectGenerator {
  final Random _random;

  SectGenerator([int? seed]) : _random = Random(seed);

  /// 封闭区域选择结果
  /// 包含选中的区域ID、所有tile、以及随机挑选出的一个tile
  SectSelection pickSectLocation({
    required Map<String, Map<Point<int>, int>> chunkRegionMaps,
  }) {
    // 收集所有region
    final Map<int, List<_RegionTileInfo>> regionTilesMap = {};

    chunkRegionMaps.forEach((chunkKey, regionMap) {
      regionMap.forEach((tile, regionId) {
        regionTilesMap.putIfAbsent(regionId, () => []).add(
          _RegionTileInfo(chunkKey: chunkKey, tile: tile),
        );
      });
    });

    if (regionTilesMap.isEmpty) {
      throw Exception('没有可用的封闭地形区域');
    }

    // 随机选区域
    final allRegionIds = regionTilesMap.keys.toList();
    final selectedRegionId = allRegionIds[_random.nextInt(allRegionIds.length)];

    // 所有tile
    final tiles = regionTilesMap[selectedRegionId]!;

    // 随机选一个tile
    final selectedTile = tiles[_random.nextInt(tiles.length)];

    return SectSelection(
      regionId: selectedRegionId,
      tiles: tiles,
      selectedTile: selectedTile,
    );
  }
}

/// 选中的宗门位置
class SectSelection {
  final int regionId;
  final List<_RegionTileInfo> tiles;
  final _RegionTileInfo selectedTile;

  SectSelection({
    required this.regionId,
    required this.tiles,
    required this.selectedTile,
  });
}

/// 内部类：区域内的tile
class _RegionTileInfo {
  final String chunkKey;
  final Point<int> tile;

  _RegionTileInfo({
    required this.chunkKey,
    required this.tile,
  });
}
