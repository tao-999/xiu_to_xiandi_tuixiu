import 'dart:math';
import 'package:flutter/material.dart';

class BreakthroughAura extends StatefulWidget {
  final VoidCallback? onComplete; // 播完回调（可选）

  const BreakthroughAura({super.key, this.onComplete});

  @override
  State<BreakthroughAura> createState() => _BreakthroughAuraState();
}

class _BreakthroughAuraState extends State<BreakthroughAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scale = Tween(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = Tween(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().whenComplete(() {
      widget.onComplete?.call(); // 通知外部：动画完了
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _AuraPainter(scale: _scale.value, opacity: _opacity.value),
          child: const SizedBox(width: 160, height: 160),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AuraPainter extends CustomPainter {
  final double scale;
  final double opacity;

  _AuraPainter({required this.scale, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.3 * scale;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amber.withOpacity(opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      scale != old.scale || opacity != old.opacity;
}
