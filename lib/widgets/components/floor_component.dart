import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloorComponent extends PositionComponent {
  final int rows, cols;
  final double tileSize;

  FloorComponent({
    required this.rows,
    required this.cols,
    required this.tileSize,
  });

  @override
  Future<void> onLoad() async {
    size = Vector2(cols * tileSize, rows * tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFFDDDDDD), // 底板颜色你可以自行改
    );
  }
}
