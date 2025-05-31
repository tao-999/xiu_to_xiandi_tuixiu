import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';

class YouliMapGame extends FlameGame {
  late final SpriteComponent bg;

  @override
  Future<void> onLoad() async {
    // 加载地图贴图
    bg = SpriteComponent()
      ..sprite = await loadSprite('bg_map_youli_horizontal.png')
      ..size = Vector2(3000, 2400)
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft;

    // ✅ 设置初始缩放倍率（例如 0.4倍）
    bg.scale = Vector2.all(0.4);

    add(bg);

    // 添加拖动组件
    add(_DragMap(onDragged: _onDragged));
  }

  void _onDragged(Vector2 delta) {
    bg.position += delta;
    _clampPosition();
    print('📍 拖动后 bg.position: ${bg.position}');
  }

  void _clampPosition() {
    final screen = canvasSize;
    final scaledSize = bg.size.clone()..multiply(bg.scale);

    final double maxX = 0.0;
    final double maxY = 0.0;
    final double minX = screen.x - scaledSize.x;
    final double minY = screen.y - scaledSize.y;

    bg.position.x = bg.position.x.clamp(minX, maxX);
    bg.position.y = bg.position.y.clamp(minY, maxY);
  }
}

class _DragMap extends PositionComponent with DragCallbacks {
  final void Function(Vector2 delta) onDragged;

  _DragMap({required this.onDragged}) {
    size = Vector2.all(99999); // 全屏覆盖
    position = Vector2.zero();
    priority = 9999;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final delta = event.localDelta;
    print('✅ 拖动 delta: $delta');
    onDragged(delta);
  }
}
