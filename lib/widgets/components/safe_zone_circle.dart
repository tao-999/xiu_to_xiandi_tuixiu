import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SafeZoneCircle extends PositionComponent {
  final double radius; // 外圈半径
  final Paint borderPaint;
  final Paint innerCirclePaint;
  final Paint starPaint;

  SafeZoneCircle({
    required Vector2 center,
    required this.radius,
    Color color = Colors.white,
    Color starColor = Colors.white,
    Color innerCircleColor = Colors.white,
  })  : borderPaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5,
        innerCirclePaint = Paint()
          ..color = innerCircleColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
        starPaint = Paint()
          ..color = starColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
        super(
        position: center,
        anchor: Anchor.center,
        priority: 50,
      );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. 外圈
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    // 2. 内圈（间距10）
    const gap = 10.0;
    final innerRadius = radius - gap;
    canvas.drawCircle(Offset.zero, innerRadius, innerCirclePaint);

    // 3. 五芒星（画在内圈上）
    final List<Offset> vertices = [];
    final double angleStep = 2 * pi / 5;
    final double startAngle = -pi / 2;

    for (int i = 0; i < 5; i++) {
      double angle = startAngle + i * angleStep;
      vertices.add(Offset(
        cos(angle) * innerRadius,
        sin(angle) * innerRadius,
      ));
    }

    // 五芒星一笔画法
    final starPath = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    starPath.lineTo(vertices[2].dx, vertices[2].dy);
    starPath.lineTo(vertices[4].dx, vertices[4].dy);
    starPath.lineTo(vertices[1].dx, vertices[1].dy);
    starPath.lineTo(vertices[3].dx, vertices[3].dy);
    starPath.close();

    canvas.drawPath(starPath, starPaint);
  }
}
