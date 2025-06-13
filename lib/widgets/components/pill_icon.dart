import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_recipe.dart';

class PillIcon extends StatelessWidget {
  final PillType type;
  final int level;
  final double size;

  const PillIcon({
    super.key,
    required this.type,
    required this.level,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      PillType.attack => const Color(0xFFEB4D4B),   // 🔴 攻击红
      PillType.defense => const Color(0xFF1ABC9C),  // 🟢 防御绿
      PillType.health => const Color(0xFFF39C12),   // 🟡 血气橙
    };

    return CustomPaint(
      size: Size.square(size),
      painter: _PillIconPainter(color: color, level: level),
    );
  }
}

class _PillIconPainter extends CustomPainter {
  final Color color;
  final int level;

  _PillIconPainter({required this.color, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 🌀 绘制圆形渐变球体
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.95),
        color.withOpacity(0.7),
        color.withOpacity(0.2), // ✅ 外圈也是主色，整体统一
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // ✨ 绘制顶部高光（假透视）
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(-radius / 3, -radius / 3), radius / 3.2, highlightPaint);

    // 🔢 绘制中间的“X阶”文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontSize: size.width * 0.32, // ✅ 取 Size 的宽度
          fontFamily: 'ZcoolCangEr',
          color: Colors.white,
          shadows: const [
            Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1)),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
