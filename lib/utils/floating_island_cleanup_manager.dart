import 'dart:ui';
import 'package:flame/components.dart';

import '../services/floating_island_storage.dart';
import '../widgets/components/floating_island_dynamic_mover_component.dart';
import '../widgets/components/floating_island_dynamic_spawner_component.dart';
import '../widgets/components/has_logical_position.dart';

class FloatingIslandCleanupManager extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;

  /// 比Spawner大得多的清理范围
  final double bufferSize;

  /// 排除组件
  final Set<Component> excludeComponents;

  FloatingIslandCleanupManager({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    this.bufferSize = 2000, // 超大buffer避免打架
    this.excludeComponents = const {},
  });

  @override
  Future<void> update(double dt) async {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    final cleanupRect = Rect.fromCenter(
      center: Offset(offset.x, offset.y),
      width: viewSize.x + bufferSize * 2,
      height: viewSize.y + bufferSize * 2,
    );

    final dynamicTileStates = <String, List<Map<String, dynamic>>>{};
    final alreadySavedDynamicTiles = <String>{};

    final toRemove = <Component>[];

    for (final c in grid.children) {
      if (excludeComponents.contains(c)) continue;

      if (c is FloatingIslandDynamicMoverComponent) {
        final pos = c.logicalPosition;
        if (!cleanupRect.contains(Offset(pos.x, pos.y))) {
          final dynamicTileSize = c.dynamicTileSize;
          final tileX = (pos.x / dynamicTileSize).floor();
          final tileY = (pos.y / dynamicTileSize).floor();
          final tileKey = '${tileX}_${tileY}';

          if (!alreadySavedDynamicTiles.contains(tileKey)) {
            dynamicTileStates.putIfAbsent(tileKey, () => []).add({
              'path': c.spritePath,
              'x': pos.x,
              'y': pos.y,
              'size': c.size.x,
              'speed': c.speed,
            });
            alreadySavedDynamicTiles.add(tileKey);
          }

          if (c.spawner is FloatingIslandDynamicSpawnerComponent) {
            (c.spawner as FloatingIslandDynamicSpawnerComponent).loadedDynamicTiles.remove(tileKey);
          }
          toRemove.add(c);
        }
      }
      // ⚠️静态贴图和其他组件不再清理
    }

    // 批量写入（只保存动态）
    final futures = <Future>[];
    dynamicTileStates.forEach((tileKey, states) {
      futures.add(FloatingIslandStorage.saveDynamicObjectsForTile(tileKey, states));
    });
    await Future.wait(futures);

    // 移除
    for (final c in toRemove) {
      c.removeFromParent();
    }
  }
}
