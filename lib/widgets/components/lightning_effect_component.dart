import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LightningEffectComponent extends PositionComponent {
  final Vector2 source;
  final Vector2 target;
  final int segments;
  final double deviation;
  final Color color;
  final double lifespan;

  double age = 0;
  final Random rng = Random();

  LightningEffectComponent({
    required this.source,
    required this.target,
    this.segments = 6,
    this.deviation = 10.0,
    this.color = Colors.white,
    this.lifespan = 0.3,
  }) {
    position = Vector2.zero();
    size = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (age >= lifespan) {
      removeFromParent();
    }
  }

  List<Vector2> _generateLightningPath(
      Vector2 from, Vector2 to, int segments, double deviation) {
    final points = <Vector2>[];
    points.add(from);
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final intermediate = from + (to - from) * t;
      final offset = Vector2(
        (rng.nextDouble() - 0.5) * deviation * 2,
        (rng.nextDouble() - 0.5) * deviation * 2,
      );
      points.add(intermediate + offset);
    }
    points.add(to);
    return points;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = _generateLightningPath(source, target, segments, deviation);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      canvas.drawLine(p1.toOffset(), p2.toOffset(), paint);

      // 分叉线（10% 概率）
      if (rng.nextDouble() < 0.1) {
        final forkLength = 10 + rng.nextDouble() * 15;
        final forkAngle = rng.nextDouble() * pi * 2;
        final forkOffset = Vector2(cos(forkAngle), sin(forkAngle)) * forkLength;
        final forkEnd = p1 + forkOffset;
        canvas.drawLine(p1.toOffset(), forkEnd.toOffset(), paint..strokeWidth = 1);
      }
    }
  }
}
