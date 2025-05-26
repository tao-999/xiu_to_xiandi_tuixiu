import 'dart:math';
import 'dart:ui'; // 为 lerpDouble 提供支持
import 'package:flutter/material.dart';

class XiuxianParticleBackground extends StatefulWidget {
  const XiuxianParticleBackground({super.key});

  @override
  State<XiuxianParticleBackground> createState() => _XiuxianParticleBackgroundState();
}

class _XiuxianParticleBackgroundState extends State<XiuxianParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_PathParticle> _particles = [];
  final int particleCount = 40;
  final Random rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..addListener(_onTick);

    for (int i = 0; i < particleCount; i++) {
      _particles.add(_PathParticle(rand));
    }

    _controller.repeat();
  }

  void _onTick() {
    setState(() {
      for (final p in _particles) {
        p.update();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: _particles.map((p) {
        final offset = p.getCurrentPosition(size);
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Opacity(
            opacity: p.opacity,
            child: CustomPaint(
              size: Size.square(p.size),
              painter: _CottonPainter(p.shapeSeed, p.color),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PathParticle {
  final Random rand;
  final List<Offset> path = [];
  final List<double> segmentDurations = [];
  final int shapeSeed;
  final double size;
  final Color color;

  int currentSegment = 0;
  double timeInSegment = 0;
  double opacity = 0;

  _PathParticle(this.rand)
      : shapeSeed = rand.nextInt(999999),
        size = 80 + rand.nextDouble() * 60,
        color = Colors.white {
    _generatePath();
  }

  void _generatePath() {
    path.clear();
    segmentDurations.clear();
    Offset start = Offset(rand.nextDouble(), rand.nextDouble());
    path.add(start);

    int pointCount = 3 + rand.nextInt(2);
    for (int i = 0; i < pointCount; i++) {
      path.add(Offset(rand.nextDouble(), rand.nextDouble()));
      segmentDurations.add(12 + rand.nextDouble() * 6); // 12 ~ 18 秒
    }

    final double exitX = rand.nextBool()
        ? -0.2 + rand.nextDouble() * 0.4
        : 1.0 + rand.nextDouble() * 0.4;
    final double exitY = rand.nextBool()
        ? -0.2 + rand.nextDouble() * 0.4
        : 1.0 + rand.nextDouble() * 0.4;
    path.add(Offset(exitX, exitY));
    segmentDurations.add(12 + rand.nextDouble() * 6); // 12 ~ 18 秒
  }

  void update() {
    timeInSegment += 1 / 60;

    if (currentSegment >= path.length - 1) {
      _reset();
      return;
    }

    double duration = segmentDurations[currentSegment];
    if (timeInSegment >= duration) {
      timeInSegment = 0;
      currentSegment++;
      return;
    }

    final t = totalProgress;
    if (t < 0.1) {
      opacity = t / 0.1;
    } else if (t > 0.9) {
      opacity = (1 - t) / 0.1;
    } else {
      opacity = 0.3;
    }
  }

  Offset getCurrentPosition(Size screenSize) {
    if (currentSegment >= path.length - 1) return Offset(-9999, -9999);
    double t = (timeInSegment / segmentDurations[currentSegment]).clamp(0.0, 1.0);
    Offset p1 = path[currentSegment];
    Offset p2 = path[currentSegment + 1];

    final dx = lerpDouble(p1.dx, p2.dx, t)! * screenSize.width;
    final dy = lerpDouble(p1.dy, p2.dy, t)! * screenSize.height;
    return Offset(dx, dy);
  }

  double get totalProgress {
    final total = segmentDurations.take(currentSegment).fold(0.0, (a, b) => a + b) +
        timeInSegment;
    final full = segmentDurations.fold(0.0, (a, b) => a + b);
    return (total / full).clamp(0.0, 1.0);
  }

  void _reset() {
    currentSegment = 0;
    timeInSegment = 0;
    opacity = 0;
    _generatePath();
  }
}

class _CottonPainter extends CustomPainter {
  final int seed;
  final Color color;

  _CottonPainter(this.seed, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(seed);
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;

    final baseRadius = size.width / 4;
    final blobs = 4 + rand.nextInt(4);
    for (int i = 0; i < blobs; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final dist = rand.nextDouble() * size.width * 0.3;
      final offset = Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist,
      );
      final r = baseRadius * (0.8 + rand.nextDouble() * 0.6);
      canvas.drawCircle(offset, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
