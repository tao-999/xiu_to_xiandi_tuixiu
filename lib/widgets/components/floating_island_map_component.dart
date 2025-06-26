import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';

class FloatingIslandMapComponent extends FlameGame {
  late final DragMap _dragMap;
  late final InfiniteGridPainterComponent _grid;
  FloatingIslandPlayerComponent? player; // 公开字段

  Vector2 cameraOffset = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _grid = InfiniteGridPainterComponent();

    _dragMap = DragMap(
      onDragged: (delta) {
        cameraOffset += delta;
        _grid.position = cameraOffset.clone();
      },
      onTap: (tapPos) {
        final worldPos = tapPos - _grid.position;
        player?.moveTo(worldPos);
      },
      showGrid: false,
      childBuilder: () => _grid,
    );

    add(_dragMap);

    await Future.delayed(Duration.zero);
    cameraOffset = size / 2;
    _grid.position = cameraOffset.clone();

    player = FloatingIslandPlayerComponent(
      onPositionChanged: (pos) {
        cameraOffset = size / 2 - pos;
        _grid.position = cameraOffset.clone();
      },
    )
      ..position = Vector2.zero()
      ..anchor = Anchor.center;

    _grid.add(player!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _grid
      ..viewScale = 1.0
      ..viewSize = size.clone();
  }

  void resetToCenter() {
    cameraOffset = size / 2;
    _grid.position = cameraOffset.clone();
  }
}
