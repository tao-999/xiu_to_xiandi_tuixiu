import 'package:flutter/material.dart';

class FantasyRadioGroup extends StatelessWidget {
  final String groupLabel;
  final String selected;
  final List<String> options;
  final void Function(String) onChanged;

  const FantasyRadioGroup({
    super.key,
    required this.groupLabel,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  String _getDisplayText(String value) {
    switch (value) {
      case "male":
        return "男修";
      case "female":
        return "女修";
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 👉 Label：右对齐 + 固定宽度
        SizedBox(
          width: 88,
          child: Text(
            groupLabel,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),

        // 👉 内容：左对齐
        Row(
          children: options.map((opt) {
            final isSelected = selected == opt;
            final display = _getDisplayText(opt);

            return GestureDetector(
              onTap: () => onChanged(opt),
              child: Row(
                children: [
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: _RadioPainter(selected: isSelected),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    display,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RadioPainter extends CustomPainter {
  final bool selected;

  _RadioPainter({required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF9C8E7B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    if (selected) {
      final checkPaint = Paint()
        ..color = const Color(0xFF5E4B36)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(size.width * 0.25, size.height * 0.55),
        Offset(size.width * 0.45, size.height * 0.75),
        checkPaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.45, size.height * 0.75),
        Offset(size.width * 0.75, size.height * 0.25),
        checkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
