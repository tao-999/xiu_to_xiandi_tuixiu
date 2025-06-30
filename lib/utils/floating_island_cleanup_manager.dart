import 'dart:ui';
import 'package:flame/components.dart';

import '../services/floating_island_storage.dart';
import '../widgets/components/floating_island_dynamic_mover_component.dart';
import '../widgets/components/has_logical_position.dart';

class FloatingIslandCleanupManager extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final double bufferSize;

  /// 🌟 排除组件
  final Set<Component> excludeComponents;

  FloatingIslandCleanupManager({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    this.bufferSize = 500,
    this.excludeComponents = const {},
  });

  @override
  void update(double dt) {
    super.update(dt);

    final offset = getLogicalOffset();
    final viewSize = getViewSize();
    final visibleRect = Rect.fromCenter(
      center: Offset(offset.x, offset.y),
      width: viewSize.x + bufferSize * 2,
      height: viewSize.y + bufferSize * 2,
    );

    // key = tileKey, value = list of states
    final Map<String, List<Map<String, dynamic>>> tileStates = {};

    final toRemove = <Component>[];

    for (final c in grid.children) {
      if (excludeComponents.contains(c)) continue;

      if (c is FloatingIslandDynamicMoverComponent) {
        final pos = c.logicalPosition;
        if (!visibleRect.contains(Offset(pos.x, pos.y))) {
          final dynamicTileSize = c.spawner.dynamicTileSize;
          final tileX = (pos.x / dynamicTileSize).floor();
          final tileY = (pos.y / dynamicTileSize).floor();
          final tileKey = '${tileX}_${tileY}';

          tileStates.putIfAbsent(tileKey, () => []).add({
            'path': c.spritePath,
            'x': pos.x,
            'y': pos.y,
            'size': c.size.x,
            'speed': c.speed,
          });

          // 🌟移除加载状态，只移除它所属Spawner
          c.spawner.loadedDynamicTiles.remove(tileKey);

          toRemove.add(c);
        }
      } else if (c is PositionComponent) {
        final pos = c is HasLogicalPosition
            ? (c as HasLogicalPosition).logicalPosition
            : c.position + offset;

        if (!visibleRect.contains(Offset(pos.x, pos.y))) {
          toRemove.add(c);
        }
      }
    }

    // 🌟写入Hive
    tileStates.forEach((tileKey, states) async {
      await FloatingIslandStorage.saveDynamicObjectsForTile(tileKey, states);
    });

    // 🌟移除
    for (final c in toRemove) {
      c.removeFromParent();
    }
  }
}
