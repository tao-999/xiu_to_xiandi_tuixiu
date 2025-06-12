import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class TouchEffectOverlay extends StatefulWidget {
  const TouchEffectOverlay({super.key});

  @override
  State<TouchEffectOverlay> createState() => _TouchEffectOverlayState();
}

class _TouchEffectOverlayState extends State<TouchEffectOverlay> {
  final List<_InkSplash> _splashes = [];

  void _addEffect(Offset localPosition) {
    final splash = _InkSplash(localPosition, key: UniqueKey());
    setState(() => _splashes.add(splash));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _splashes.remove(splash));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(event.position);
        _addEffect(localPos);
      },
      child: Stack(children: _splashes),
    );
  }
}

class _InkSplash extends StatefulWidget {
  final Offset position;
  const _InkSplash(this.position, {super.key});

  @override
  State<_InkSplash> createState() => _InkSplashState();
}

class _InkSplashState extends State<_InkSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _size = Tween<double>(begin: 10.0, end: 80.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final size = _size.value;
        return Positioned(
          left: widget.position.dx - size / 2,
          top: widget.position.dy - size / 2,
          child: Opacity(
            opacity: _opacity.value,
            child: CustomPaint(
              size: Size.square(size),
              painter: _InkBurstPainter(),
            ),
          ),
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

class _InkBurstPainter extends CustomPainter {
  final Random _rand = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()..moveTo(center.dx, center.dy);

    for (int i = 0; i < 10; i++) {
      final angle = i * pi / 5;
      final radius = 20 + _rand.nextDouble() * 20;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      path.quadraticBezierTo(center.dx, center.dy, dx, dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
