import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class VfxHitExplosion extends PositionComponent {
  final Vector2 centerLocal;   // 父层本地
  final double radius;
  final double life;
  final Color color;
  final int? basePriority;

  double _t = 0;

  VfxHitExplosion({
    required this.centerLocal,
    this.radius = 24,
    this.life = 0.22,
    this.color = const Color(0xFFFFE082),
    this.basePriority,
  }) {
    anchor = Anchor.center;
    position = centerLocal.clone();
    size = Vector2.all(radius * 2.2);
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final k = (_t / life).clamp(0.0, 1.0);
    final coreR  = radius * (0.55 + 0.40 * (1.0 - k));
    final ringR  = radius * (0.95 + 0.70 * k);
    final glowR  = radius * (1.70 + 1.10 * k);

    // 1) 白热核心
    final core = Paint()
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withOpacity(0.95 * (1.0 - k));
    canvas.drawCircle(Offset.zero, coreR, core);

    // 2) 渐变圈
    final shader = ui.Gradient.radial(
      Offset.zero,
      ringR,
      [Colors.white, color, const Color(0xFFFF9800), const Color(0xFFEF6C00)],
      const [0.0, 0.25, 0.65, 1.0],
    );
    final mid = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset.zero, ringR, mid);

    // 3) 热边亮环
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.22).clamp(2.0, 6.0)
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withOpacity(0.85 * (1.0 - k * 0.6));
    canvas.drawCircle(Offset.zero, ringR * 0.96, ring);

    // 4) 外部大光晕
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..color = color.withOpacity(0.55 * (1.0 - k))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset.zero, glowR, glow);
  }
}
