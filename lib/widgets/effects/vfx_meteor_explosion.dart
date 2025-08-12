import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 流星冲击爆炸（本地坐标）
class VfxMeteorExplosion extends PositionComponent {
  final Vector2 centerLocal;
  final double radius;         // AOE 半径
  final double life;           // 生命周期
  final int? basePriority;

  final int sparkCount;
  final int smokeCount;

  final Random _rng = Random();
  double _t = 0.0;

  late final List<_Spark> _sparks;
  late final List<_Smoke> _smokes;

  VfxMeteorExplosion({
    required this.centerLocal,
    required this.radius,
    this.life = 0.32,
    this.basePriority,
    this.sparkCount = 18,
    this.smokeCount = 6,
  }) {
    anchor = Anchor.center;            // 落点为锚点
    position = centerLocal.clone();
    size = Vector2.all(radius * 2.8);
    if (basePriority != null) priority = basePriority!;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _sparks = List.generate(sparkCount, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      final spd = radius * (0.9 + _rng.nextDouble() * 0.6);
      final life = 0.18 + _rng.nextDouble() * 0.12;
      return _Spark(vx: cos(ang) * spd, vy: sin(ang) * spd, life: life, size: 2 + _rng.nextDouble() * 2);
    });
    _smokes = List.generate(smokeCount, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      final off = radius * 0.12 * _rng.nextDouble();
      final life = 0.35 + _rng.nextDouble() * 0.25;
      return _Smoke(
        x: cos(ang) * off, y: sin(ang) * off,
        vx: cos(ang) * (20 + _rng.nextDouble() * 30),
        vy: sin(ang) * (20 + _rng.nextDouble() * 30),
        life: life, r0: radius * (0.18 + _rng.nextDouble() * 0.12),
      );
    });
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / life).clamp(0.0, 1.0);

    // ✅ 把原点移到组件中心，再以 (0,0) 为圆心绘制
    canvas.save();
    canvas.translate(size.x * 0.5, size.y * 0.5);

    // 1) 中心闪光（柔和渐变）
    final flashA = (1.0 - k).clamp(0.0, 1.0);
    if (flashA > 0) {
      final shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95 * flashA),
          const Color(0xFFFFF59D).withOpacity(0.55 * flashA),
          const Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 0.55));
      final flash = Paint()..blendMode = BlendMode.plus..shader = shader;
      canvas.drawCircle(Offset.zero, radius * (0.35 + 0.25 * (1 - k)), flash);
    }

    // 2) 热浪朦胧（无描边圈）
    final heatFill = Paint()
      ..blendMode = BlendMode.plus
      ..color = const Color(0xFFFFA726).withOpacity(0.20 * (1 - k))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, radius * (0.70 + 0.25 * k), heatFill);

    // 3) 灰尘/暗影盘
    final dust = Paint()..style = PaintingStyle.fill
      ..color = const Color(0xFF3E2723).withOpacity(0.18 * (1 - k));
    canvas.drawCircle(Offset.zero, radius * (0.55 + 0.35 * k), dust);

    // 4) 火星
    final sparkGlow = Paint()..blendMode = BlendMode.plus..color = const Color(0xFFFFC107).withOpacity(0.30);
    final sparkCore = Paint()..blendMode = BlendMode.plus..color = const Color(0xFFFFF176).withOpacity(0.90);
    for (final s in _sparks) {
      final a = s.alpha(_t);
      if (a <= 0) continue;
      final off = Offset(s.x, s.y);
      canvas.drawCircle(off, s.size * 2.2, sparkGlow..color = sparkGlow.color.withOpacity(0.25 * a));
      canvas.drawCircle(off, s.size,      sparkCore..color = sparkCore.color.withOpacity(0.85 * a));
    }

    // 5) 烟团
    final smokeP = Paint()..blendMode = BlendMode.srcOver..color = const Color(0xFF6D4C41).withOpacity(0.18);
    for (final p in _smokes) {
      final a = p.alpha(_t);
      if (a <= 0) continue;
      canvas.drawCircle(Offset(p.x, p.y), p.radius(_t), smokeP..color = smokeP.color.withOpacity(0.20 * a));
    }

    canvas.restore();
  }

  @override
  void update(double dt) {
    _t += dt;
    for (final s in _sparks) s.update(dt);
    for (final p in _smokes) p.update(dt);
    if (_t >= life) removeFromParent();
  }
}

class _Spark {
  double x = 0, y = 0;
  final double vx, vy, life, size;
  double t = 0;
  _Spark({required this.vx, required this.vy, required this.life, required this.size});
  void update(double dt) { t += dt; x += vx * dt; y += vy * dt; }
  double alpha(double now) => (1 - (t / life).clamp(0.0, 1.0));
}

class _Smoke {
  double x, y; final double vx, vy, life, r0; double t = 0;
  _Smoke({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.r0});
  void update(double dt){ t += dt; x += vx * dt; y += vy * dt; }
  double alpha(double now)=> (1 - (t / life).clamp(0.0, 1.0));
  double radius(double now){ final k=(t/life).clamp(0.0,1.0); return r0*(1+0.9*k); }
}
