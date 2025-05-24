// 通用五边形雷达图组件
import 'package:flutter/material.dart';
import 'dart:math';

class PolygonRadarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final int max;
  final Color strokeColor;
  final Color fillColor;
  final TextStyle labelStyle;

  const PolygonRadarChart({
    super.key,
    required this.values,
    required this.labels,
    this.max = 15,
    this.strokeColor = Colors.teal,
    this.fillColor = const Color.fromARGB(100, 0, 128, 128),
    this.labelStyle = const TextStyle(fontSize: 14, color: Colors.black),
  }) : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(240, 240),
      painter: _PolygonRadarPainter(
        values: values,
        labels: labels,
        max: max,
        strokeColor: strokeColor,
        fillColor: fillColor,
        labelStyle: labelStyle,
      ),
    );
  }
}

class _PolygonRadarPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final int max;
  final Color strokeColor;
  final Color fillColor;
  final TextStyle labelStyle;

  _PolygonRadarPainter({
    required this.values,
    required this.labels,
    required this.max,
    required this.strokeColor,
    required this.fillColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final angle = 2 * pi / values.length;
    final paintLine = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 画外圈网格
    for (int i = 1; i <= 3; i++) {
      final r = radius * (i / 3);
      final points = List.generate(values.length, (index) {
        final a = angle * index - pi / 2;
        return Offset(center.dx + cos(a) * r, center.dy + sin(a) * r);
      });
      canvas.drawPath(Path()..addPolygon(points, true), paintLine);
    }

    // 画轴线 & 标签
    for (int i = 0; i < values.length; i++) {
      final a = angle * i - pi / 2;
      final dx = cos(a) * radius;
      final dy = sin(a) * radius;
      canvas.drawLine(center, center + Offset(dx, dy), paintLine);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        center + Offset(dx * 1.1, dy * 1.1) - Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
    }

    // 画数据图形（避免回到圆心，最低为1）
    final dataPoints = List.generate(values.length, (index) {
      final rawValue = values[index].clamp(0, max);
      final value = rawValue <= 1 ? 1 : rawValue;
      final ratio = value / max;
      final a = angle * index - pi / 2;
      return Offset(
        center.dx + cos(a) * radius * ratio,
        center.dy + sin(a) * radius * ratio,
      );
    });

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(Path()..addPolygon(dataPoints, true), paintFill);
    canvas.drawPath(Path()..addPolygon(dataPoints, true), paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}