import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';

import '../../models/disciple.dart';

class FavorabilityHeart extends StatefulWidget {
  final Disciple disciple;

  /// 🌟 回调
  final ValueChanged<Disciple>? onFavorabilityChanged;

  const FavorabilityHeart({
    Key? key,
    required this.disciple,
    this.onFavorabilityChanged,
  }) : super(key: key);

  @override
  State<FavorabilityHeart> createState() => _FavorabilityHeartState();
}

class _FavorabilityHeartState extends State<FavorabilityHeart> {
  late int _favorability;

  @override
  void initState() {
    super.initState();
    _favorability = widget.disciple.favorability;
  }

  Future<void> _incrementFavorability() async {
    final updated = await ZongmenDiscipleService.increaseFavorability(
      widget.disciple.id,
      delta: 10, // ✅ 改成 +10
    );
    if (updated != null) {
      setState(() {
        _favorability = updated.favorability;
      });
      widget.onFavorabilityChanged?.call(updated);
    }
  }

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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '提升好感度',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _incrementFavorability();
                    },
                    child: const Text('+10'),
                  ),
                ],
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
              '$_favorability',
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
