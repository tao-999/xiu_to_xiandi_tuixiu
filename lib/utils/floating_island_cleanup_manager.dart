import 'dart:ui';
import 'package:flame/components.dart';

class FloatingIslandCleanupManager extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final double bufferSize;

  /// 🌟 新增：排除组件列表
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

    final toRemove = <Component>[];

    for (final c in grid.children) {
      // 🌟 如果在排除列表，跳过
      if (excludeComponents.contains(c)) continue;

      if (c is PositionComponent) {
        final pos = c is HasLogicalPosition
            ? (c as HasLogicalPosition).logicalPosition
            : c.position + offset;

        if (!visibleRect.contains(Offset(pos.x, pos.y))) {
          toRemove.add(c);
        }
      }
    }

    for (final c in toRemove) {
      c.removeFromParent();
    }
  }
}

/// 可选：让需要“逻辑坐标”的组件实现这个接口
mixin HasLogicalPosition {
  Vector2 get logicalPosition;
}
