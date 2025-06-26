import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';

class FloatingIslandMapComponent extends FlameGame {
  late final DragMap _dragMap;
  late final InfiniteGridPainterComponent _grid;

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
      showGrid: false,
      childBuilder: () => _grid,
    );

    add(_dragMap);

    // ✅ 默认初始化时，将(0,0)显示在屏幕中央
    await Future.delayed(Duration.zero); // 等待 size 可用
    cameraOffset = size / 2;
    _grid.position = cameraOffset.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _grid
      ..viewScale = 1.0
      ..viewSize = size.clone();
  }

  /// 📍 一键返回地图中心
  void resetToCenter() {
    cameraOffset = size / 2;
    _grid.position = cameraOffset.clone();
  }
}
