import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 命中闪光：小电弧爆点
class VfxLightningHitFlash extends PositionComponent {
  final double life;
  final double sizePx;
  final Color color;
  final int? basePriority;
  double _t = 0;

  VfxLightningHitFlash({
    required Vector2 worldPos,
    this.life = 0.12,
    this.sizePx = 18,
    this.color = const Color(0xFFCCFFFF),
    this.basePriority,
  }) {
    position = worldPos.clone();
    anchor = Anchor.center;
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / life).clamp(0.0, 1.0);
    final r = sizePx * (0.7 + 0.6 * p);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1 - p)
      ..color = color.withOpacity(1 - p);
    canvas.drawCircle(Offset.zero, r, ring);

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.22 * (1 - p));
    canvas.drawCircle(Offset.zero, r * 0.65, fill);
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= life) removeFromParent();
  }
}
