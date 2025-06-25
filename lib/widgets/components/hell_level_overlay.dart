import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HellLevelOverlay extends TextComponent with HasGameRef {
  final int Function() getLevel;

  HellLevelOverlay({required this.getLevel})
      : super(
    text: '',
    anchor: Anchor.topRight,
    position: Vector2.zero(), // ⚠️ 推迟设置
    textRenderer: TextPaint(
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 2, color: Colors.redAccent)],
      ),
    ),
    priority: 1000,
  );

  @override
  Future<void> onLoad() async {
    // ✅ 获取当前视口宽度，设置右上角位置
    position = Vector2(gameRef.size.x - 8, 36);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = '第 ${getLevel()} 层';
  }
}