import 'package:flutter/material.dart';

class FavorabilityHeart extends StatelessWidget {
  final int favorability;

  const FavorabilityHeart({Key? key, required this.favorability}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: const Color(0xFFFFF8DC), // 米黄色
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // 直角
            ),
            child: Container(
              width: 200,
              height: 120,
              alignment: Alignment.center,
              child: const Text(
                '', // 先空着
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        );
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: _HeartPainter(),
          child: Center(
            child: Text(
              '$favorability',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
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
      width * 1.2, height * 0.6, // Control point 1
      width * 0.8, height * 0.1, // Control point 2
      width / 2, height * 0.3,   // End point
    );

    path.cubicTo(
      width * 0.2, height * 0.1, // Control point 3
      -width * 0.2, height * 0.6, // Control point 4
      width / 2, height * 0.8,   // Back to start
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
