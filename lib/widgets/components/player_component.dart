import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  Vector2? target;            // 当前移动目标点
  final double speed = 200.0; // px / 秒，自由调节
  final Paint _paint = Paint()..color = Colors.orange;

  PlayerComponent() {
    size = Vector2.all(50);   // 一格大小
    anchor = Anchor.center;   // 中心定位，代表站在该点
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size / 2;

    // 火柴人简易画
    // 头
    canvas.drawCircle(Offset(center.x, center.y - 10), 8, _paint);

    // 身体
    canvas.drawLine(
      Offset(center.x, center.y - 2),
      Offset(center.x, center.y + 12),
      _paint,
    );

    // 手
    canvas.drawLine(
      Offset(center.x - 10, center.y + 2),
      Offset(center.x + 10, center.y + 2),
      _paint,
    );

    // 腿
    canvas.drawLine(
      Offset(center.x, center.y + 12),
      Offset(center.x - 8, center.y + 22),
      _paint,
    );
    canvas.drawLine(
      Offset(center.x, center.y + 12),
      Offset(center.x + 8, center.y + 22),
      _paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (target != null) {
      final direction = target! - position;
      final distance = direction.length;

      if (distance < speed * dt) {
        position = target!;
        target = null;
      } else {
        position += direction.normalized() * speed * dt;
      }
    }
  }
}
