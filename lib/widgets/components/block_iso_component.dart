import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BlockIsoComponent extends PositionComponent {
  BlockIsoComponent({
    required super.position,
    required super.size,
  }) {
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    final double halfW = w / 2;
    final double halfH = h / 2;

    // 假设厚度为 20 像素
    const double depth = 20;

    // 顶面（菱形）
    final top = Path()
      ..moveTo(0, -halfH)
      ..lineTo(halfW, 0)
      ..lineTo(0, halfH)
      ..lineTo(-halfW, 0)
      ..close();

    // 左侧面
    final left = Path()
      ..moveTo(-halfW, 0)
      ..lineTo(0, halfH)
      ..lineTo(0, halfH + depth)
      ..lineTo(-halfW, depth)
      ..close();

    // 右侧面
    final right = Path()
      ..moveTo(halfW, 0)
      ..lineTo(0, halfH)
      ..lineTo(0, halfH + depth)
      ..lineTo(halfW, depth)
      ..close();

    canvas.drawPath(top, Paint()..color = Colors.brown.shade300);
    canvas.drawPath(left, Paint()..color = Colors.brown.shade500);
    canvas.drawPath(right, Paint()..color = Colors.brown.shade700);
  }
}
