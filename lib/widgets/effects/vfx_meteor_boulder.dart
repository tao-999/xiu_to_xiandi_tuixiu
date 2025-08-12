import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 流星下落（本地坐标）。到地面回调 onImpact。
class VfxMeteorBoulder extends PositionComponent {
  final Vector2 fromLocal;
  final Vector2 impactLocal;       // ← 原 toLocal 改名，避免与 PositionComponent.toLocal() 冲突
  final double fallTime;
  final double? delayStart;
  final int? basePriority;
  final VoidCallback onImpact;

  double _t = 0;
  bool _started = false;
  final Random _rng = Random();

  VfxMeteorBoulder({
    required this.fromLocal,
    required this.impactLocal,     // ← 这里也改
    required this.fallTime,
    required this.onImpact,
    this.delayStart = 0.0,
    this.basePriority,
  }) {
    anchor = Anchor.center;
    position = fromLocal.clone();
    size = Vector2.all(36);
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void update(double dt) {
    if (!_started) {
      final d = (delayStart ?? 0);
      if (_t >= d) {
        _started = true;
        _t = 0;
      } else {
        _t += dt;
        return;
      }
    }

    _t += dt;
    final k = (_t / fallTime).clamp(0.0, 1.0);

    // 简单 easeIn（加速下落）
    final e = k * k;
    position = fromLocal + (impactLocal - fromLocal) * e; // ← 使用 impactLocal

    // 落地
    if (_t >= fallTime) {
      onImpact();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / fallTime).clamp(0.0, 1.0);
    final scale = 0.6 + 0.5 * k; // 越接近越大
    canvas.scale(scale, scale);

    // 尾焰（plus）
    final trail = Paint()
      ..blendMode = BlendMode.plus
      ..color = const Color(0xFFFFAB40).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final dir = (impactLocal - fromLocal).normalized(); // ← 使用 impactLocal
    final back = Offset(-dir.x * 18, -dir.y * 18);
    canvas.drawOval(Rect.fromCenter(center: back, width: 22, height: 12), trail);

    // 岩体本体
    final body = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset.zero, 10, body);

    // 热边亮点
    final rim = Paint()
      ..blendMode = BlendMode.plus
      ..color = const Color(0xFFFFE082).withOpacity(0.9);
    final jitter = Offset((_rng.nextDouble()-0.5)*2, (_rng.nextDouble()-0.5)*2);
    canvas.drawCircle(Offset(8, -2) + jitter, 3, rim);
  }
}
