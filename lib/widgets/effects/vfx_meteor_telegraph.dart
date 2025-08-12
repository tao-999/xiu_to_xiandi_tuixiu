// 📄 lib/widgets/effects/vfx_meteor_telegraph.dart
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 地面预告圈（红→白闪，越到后期越亮），坐标传入父层本地
/// warnTime <= 0 时：不渲染，首帧立刻自删
class VfxMeteorTelegraph extends PositionComponent {
  final Vector2 centerLocal;
  final double warnTime;
  final int? basePriority;
  double _t = 0;

  VfxMeteorTelegraph({
    required this.centerLocal,
    this.warnTime = 0.35,
    this.basePriority,
  }) {
    anchor = Anchor.center;
    position = centerLocal.clone();
    size = Vector2.all(140 * 2); // 画布比实际圈略大
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void render(Canvas canvas) {
    if (warnTime <= 0) return; // 直接不画
    final k = (_t / warnTime).clamp(0.0, 1.0);

    // 红色脉冲底
    final red = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + 3.0 * (1 - k)
      ..color = const Color(0xFFFF1744).withOpacity(0.65 + 0.25 * (1 - k));
    canvas.drawCircle(Offset.zero, 68, red);

    // 白色闪圈
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity((0.25 + 0.75 * k));
    canvas.drawCircle(Offset.zero, 68 * (0.92 + 0.08 * k), white);

    // 填充轻微发光
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF8A80).withOpacity(0.15 * (0.6 + 0.4 * k));
    canvas.drawCircle(Offset.zero, 68 * (0.86 + 0.06 * k), glow);
  }

  @override
  void update(double dt) {
    if (warnTime <= 0) { removeFromParent(); return; } // 立刻移除
    _t += dt;
    if (_t >= warnTime) removeFromParent();
  }
}
