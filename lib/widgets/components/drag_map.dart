import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart';

class DragMap extends PositionComponent
    with DragCallbacks, GestureHitboxes {
  final void Function(Vector2 delta) onDragged;
  final void Function(Vector2 position)? onTap;
  final ValueNotifier<bool>? isTapLocked;

  final bool showGrid;

  double scaleFactor = 1.0;

  DragMap({
    required this.onDragged,
    this.onTap,
    this.isTapLocked,
    this.showGrid = false,
  }) {
    size = Vector2(5000, 5000); // 交互区域
    priority = 9999;
    debugPrint('🔥 DragMap created: hashCode=$hashCode');
  }

  Vector2? _startPosition;
  double _totalDistance = 0;
  late DateTime _startTime;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    // ❌ 不需要 RectangleHitbox
  }

  // ✅ 这里最关键
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.scale(scaleFactor);

    if (showGrid) {
      final paint = Paint()..color = const Color(0xFF99CCFF);
      const gridSize = 64.0;
      for (double x = -size.x; x < size.x * 2; x += gridSize) {
        for (double y = -size.y; y < size.y * 2; y += gridSize) {
          canvas.drawRect(Rect.fromLTWH(x, y, gridSize - 2, gridSize - 2), paint);
        }
      }
    }

    super.render(canvas);
    canvas.restore();
  }

  @override
  void onDragStart(DragStartEvent event) {
    _startPosition = event.localPosition;
    _totalDistance = 0;
    _startTime = DateTime.now();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    onDragged(event.localDelta);
    _totalDistance += event.localDelta.length;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final duration = DateTime.now().difference(_startTime);
    if (_totalDistance < 10 && duration.inMilliseconds < 250) {
      if (isTapLocked?.value == true) return;
      onTap?.call(_startPosition ?? Vector2.zero());
    }
  }
}
