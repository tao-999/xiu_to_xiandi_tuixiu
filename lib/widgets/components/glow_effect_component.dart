import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 真·发光组件：落子闪一圈灵气扩散圆环
class GlowEffectComponent extends PositionComponent with HasGameReference {
  final Color glowColor;

  GlowEffectComponent({
    required Vector2 position,
    required double size,
    required this.glowColor,
  }) : super(
    position: position,
    size: Vector2.all(size),
    anchor: Anchor.topLeft,
    priority: 2,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 💥 放大到格子的 6 倍，直接炸裂整个棋盘
    final waveSize = size.x * 12;

    final wave = _ExpandingRipple(
      size: Vector2.all(waveSize),
      glowColor: glowColor,
    );

    add(wave);
  }
}

class _ExpandingRipple extends PositionComponent with HasPaint {
  _ExpandingRipple({
    required Vector2 size,
    required Color glowColor,
  }) : super(
    size: size,
    anchor: Anchor.center,
  ) {
    paint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.25), // 更浓一点的初始光
          Colors.transparent,
        ],
        stops: [0.3, 1.0], // 💥 改变扩散范围
        center: Alignment.center,
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    scale = Vector2.all(0.01); // 从极小的点扩散
    opacity = 1;

    addAll([
      ScaleEffect.to(
        Vector2.all(1.0), // 全尺寸扩散
        EffectController(duration: 0.7, curve: Curves.easeOutExpo),
      ),
      OpacityEffect.to(
        0,
        EffectController(duration: 0.7, curve: Curves.easeOutCubic),
        onComplete: () => parent?.removeFromParent(),
      ),
    ]);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );
  }
}
