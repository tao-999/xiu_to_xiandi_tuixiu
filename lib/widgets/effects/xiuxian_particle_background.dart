// ✨ 重构后的仙气粒子组件
import 'dart:math';
import 'package:flutter/material.dart';

class XiuxianParticleBackground extends StatefulWidget {
  const XiuxianParticleBackground({super.key});

  @override
  State<XiuxianParticleBackground> createState() => _XiuxianParticleBackgroundState();
}

class _XiuxianParticleBackgroundState extends State<XiuxianParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CloudQi> _qis = List.generate(60, (_) => _CloudQi());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _XiPainter(_qis, _controller.value),
      ),
    );
  }
}

class _CloudQi {
  late Offset position;
  late double radius;
  late double speed;
  late double opacity;
  final Random rand = Random();

  _CloudQi() {
    reset();
  }

  void reset() {
    position = Offset(rand.nextDouble(), rand.nextDouble());
    radius = rand.nextDouble() * 40 + 20; // 更大更柔和
    speed = rand.nextDouble() * 0.15 + 0.02;
    opacity = rand.nextDouble() * 0.4 + 0.5;
  }

  void update(double t) {
    final dy = position.dy - speed * 0.005;
    if (dy < -0.1) {
      reset();
      position = Offset(rand.nextDouble(), 1.1);
    } else {
      position = Offset(position.dx + sin(t * 2 * pi + radius) * 0.0002, dy);
    }
  }
}

class _XiPainter extends CustomPainter {
  final List<_CloudQi> qis;
  final double t;
  final Paint _paint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  _XiPainter(this.qis, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final q in qis) {
      q.update(t);
      _paint.color = Colors.white.withOpacity(q.opacity.clamp(0.1, 0.4));
      canvas.drawCircle(Offset(q.position.dx * size.width, q.position.dy * size.height), q.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
