import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends TextComponent with HasGameReference {
  final Vector2 velocity;
  final double lifespan;
  final double minVisibleTime;
  double _time = 0;

  Vector2 logicalPosition;

  FloatingTextComponent({
    required String text,
    required this.logicalPosition,
    Vector2? velocity,
    this.lifespan = 1.5,         // ⏱️ 默认总时长
    this.minVisibleTime = 1.0,   // ⛔ 最少显示时间
    double fontSize = 10,
    Color color = Colors.white,
  })  : velocity = velocity ?? Vector2(0, -20),
        super(
        text: text,
        anchor: Anchor.center,
        priority: 99999,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
        ),
      );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // 🚀 移动逻辑坐标
    logicalPosition += velocity * dt;

    // 🎯 计算视觉位置
    final offset = (game as dynamic).logicalOffset as Vector2;
    position = logicalPosition - offset;

    if (_time > lifespan) {
      removeFromParent(); // ⏳ 到时间直接消失！
    }
  }

  @override
  void onMount() {
    super.onMount();
    final offset = (game as dynamic).logicalOffset as Vector2;
    print('💬 [FloatingText] text="$text"');
    print('┣ 📍 逻辑坐标: $logicalPosition');
    print('┗ 🎯 视觉坐标: ${logicalPosition - offset}');
  }
}
