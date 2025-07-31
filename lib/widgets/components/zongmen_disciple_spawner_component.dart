import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../../models/disciple.dart';
import '../../../services/zongmen_storage.dart';
import 'diplomacy_noise_tile_map_generator.dart';
import 'zongmen_diplomacy_disciple_component.dart';

class ZongmenDiscipleSpawnerComponent extends Component {
  final DiplomacyNoiseTileMapGenerator map;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final String Function(Vector2) getTerrainType;
  final double tileSize;
  final int seed;

  final Set<String> _occupiedSuperTiles = {};
  bool _generated = false;

  ZongmenDiscipleSpawnerComponent({
    required this.map,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.tileSize,
    this.seed = 9527,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_generated) return;
    _generated = true;

    const double superTileSize = 256.0;
    const double borderLimit = 64.0; // ✅ 边缘限制像素

    final viewCenter = getLogicalOffset() + getViewSize() / 2;
    final buffer = getViewSize() * 1.25;

    final topLeft = viewCenter - buffer / 2;
    final bottomRight = viewCenter + buffer / 2;

    final startX = (topLeft.x / superTileSize).floor();
    final startY = (topLeft.y / superTileSize).floor();
    final endX = (bottomRight.x / superTileSize).ceil();
    final endY = (bottomRight.y / superTileSize).ceil();

    final List<Disciple> disciples = await ZongmenStorage.loadDisciples();
    disciples.sort((a, b) => (a.joinedAt ?? 0).compareTo(b.joinedAt ?? 0));
    int index = 0;

    final List<Vector2> superTiles = [];
    for (int sx = startX; sx <= endX; sx++) {
      for (int sy = startY; sy <= endY; sy++) {
        if (sx == startX || sx == endX || sy == startY || sy == endY) continue;
        superTiles.add(Vector2(sx.toDouble(), sy.toDouble()));
      }
    }

    superTiles.sort((a, b) {
      final ay = a.y.toInt();
      final by = b.y.toInt();
      final ax = a.x.toInt();
      final bx = b.x.toInt();
      return ay != by ? ay.compareTo(by) : ax.compareTo(bx);
    });

    debugPrint('📦 弟子生成 superTile 范围: [$startX,$startY] ~ [$endX,$endY]');

    for (final tile in superTiles) {
      if (index >= disciples.length) break;

      final int sx = tile.x.toInt();
      final int sy = tile.y.toInt();
      final superTileKey = '${sx}_$sy';
      if (_occupiedSuperTiles.contains(superTileKey)) continue;

      final localSeed = seed + sx * 73856093 + sy * 19349663;
      final localRng = Random(localSeed);

      final offsetX = localRng.nextDouble() * superTileSize;
      final offsetY = localRng.nextDouble() * superTileSize;

      final pos = Vector2(
        sx * superTileSize + offsetX,
        sy * superTileSize + offsetY,
      );

      final terrain = getTerrainType(pos);
      if (terrain != 'plain') continue;

      // ✅ 地图边缘 tileSize 限制：不能靠近边缘生成
      if (pos.x < borderLimit ||
          pos.y < borderLimit ||
          pos.x > map.mapWidth - borderLimit ||
          pos.y > map.mapHeight - borderLimit) {
        continue;
      }

      final disciple = disciples[index++];

      debugPrint(
        '👣 生成弟子：${disciple.name} at (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}) 地形=$terrain',
      );

      final comp = ZongmenDiplomacyDiscipleComponent(
        disciple: disciple,
        logicalPosition: pos,
      );
      await map.add(comp);

      _occupiedSuperTiles.add(superTileKey);
    }

    debugPrint('✅ ZongmenDiscipleSpawnerComponent 弟子生成完毕，共 $index 位');
  }
}
