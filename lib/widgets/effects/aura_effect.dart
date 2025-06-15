import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame/extensions.dart';

class AuraCloudEffect extends PositionComponent with HasGameReference<FlameGame> {
  late Timer _timer;
  final int density;
  final double interval;

  AuraCloudEffect({
    this.density = 6,
    this.interval = 0.15,
  });

  @override
  Future<void> onLoad() async {
    priority = 999;
    position = Vector2.zero();
    size = Vector2.zero();
    _timer = Timer(interval, repeat: true, onTick: _spawnParticles)..start();
  }

  void _spawnParticles() {
    final rand = Random();
    final rect = game.camera.visibleWorldRect;

    final colors = [
      Colors.white.withOpacity(0.5),
      const Color(0xFFCCFFFF).withOpacity(0.5),
      const Color(0xFFDDCCFF).withOpacity(0.5),
    ];

    for (int i = 0; i < density; i++) {
      final pos = Vector2(
        rect.left + rand.nextDouble() * rect.width,
        rect.top + rand.nextDouble() * rect.height,
      );

      final baseColor = colors[rand.nextInt(colors.length)];

      final particle = AcceleratedParticle(
        lifespan: 3.5 + rand.nextDouble(), // ✅ 控制粒子寿命，自动销毁
        acceleration: Vector2(0, -5),
        speed: Vector2(
          rand.nextDouble() * 8 - 4,
          -15 - rand.nextDouble() * 10,
        ),
        position: pos,
        child: CustomAuraShapeParticle(
          color: baseColor,
          radius: 30 + rand.nextDouble() * 10,
        ),
      );

      game.add(ParticleSystemComponent(particle: particle));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer.update(dt);
  }
}

class CustomAuraShapeParticle extends Particle {
  final Paint paint;
  final double radius;

  CustomAuraShapeParticle({
    required Color color,
    this.radius = 20,
    super.lifespan = 1.5,
  }) : paint = Paint()
    ..color = color
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void render(Canvas canvas) {
    final path = Path();

    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * pi * 2;
      final r = radius * (1 + sin(progress * pi * 2 + i)); // 动态扰动
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }
}
