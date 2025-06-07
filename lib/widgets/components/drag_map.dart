import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/cupertino.dart';

class DragMap extends PositionComponent
    with DragCallbacks, HasGameRef, GestureHitboxes {
  final void Function(Vector2 delta) onDragged;
  final void Function(Vector2 position)? onTap;
  final ValueNotifier<bool>? isTapLocked; // ✅ 可选锁

  DragMap({
    required this.onDragged,
    this.onTap,
    this.isTapLocked,
  }) {
    size = Vector2.all(99999); // ✅ 巨幕
    priority = 9999;
  }

  Vector2? _startPosition;
  double _totalDistance = 0;
  late DateTime _startTime;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;

    add(RectangleHitbox()
      ..size = size
      ..anchor = Anchor.topLeft
      ..collisionType = CollisionType.passive);
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
      if (isTapLocked?.value == true) return; // ✅ 拦截tap点击
      onTap?.call(_startPosition ?? Vector2.zero());
    }
  }
}
