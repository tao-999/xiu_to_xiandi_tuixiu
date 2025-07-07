import 'package:flutter/material.dart';

class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    final path = Path();
    path.moveTo(width / 2, height * 0.8);

    path.cubicTo(
      width * 1.2, height * 0.6,
      width * 0.8, height * 0.1,
      width / 2, height * 0.3,
    );

    path.cubicTo(
      width * 0.2, height * 0.1,
      -width * 0.2, height * 0.6,
      width / 2, height * 0.8,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
