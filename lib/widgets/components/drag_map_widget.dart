import 'package:flutter/material.dart';

class DragMapWidget extends StatefulWidget {
  final Widget child;
  final void Function(Offset delta) onDragged;
  final void Function(Offset position)? onTap;
  final VoidCallback? onDragEnd; // ✅ 新增：拖动结束回调
  final ValueNotifier<bool>? isTapLocked;

  const DragMapWidget({
    super.key,
    required this.child,
    required this.onDragged,
    this.onTap,
    this.onDragEnd,
    this.isTapLocked,
  });

  @override
  State<DragMapWidget> createState() => _DragMapWidgetState();
}

class _DragMapWidgetState extends State<DragMapWidget> {
  Offset? _startPosition;
  double _totalDistance = 0;
  late DateTime _startTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _startPosition = details.localPosition;
        _totalDistance = 0;
        _startTime = DateTime.now();
      },
      onPanUpdate: (details) {
        widget.onDragged(details.delta);
        _totalDistance += details.delta.distance;
      },
      onPanEnd: (details) {
        final duration = DateTime.now().difference(_startTime);
        if (_totalDistance < 10 && duration.inMilliseconds < 250) {
          if (widget.isTapLocked?.value == true) return;
          widget.onTap?.call(_startPosition ?? Offset.zero);
        }

        widget.onDragEnd?.call(); // ✅ 补上拖动结束回调
      },
      child: widget.child,
    );
  }
}
