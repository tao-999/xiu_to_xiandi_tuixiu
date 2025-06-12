import 'dart:math' as math;
import 'package:flutter/material.dart';

class FiveStarDanfangArray extends StatefulWidget {
  final String imagePath;
  final double radius;
  final double imageSize;
  final bool isRunning;
  final bool hasStarted;
  final Duration duration;

  const FiveStarDanfangArray({
    super.key,
    required this.imagePath,
    this.radius = 100,
    this.imageSize = 60,
    required this.isRunning,
    required this.hasStarted,
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<FiveStarDanfangArray> createState() => _FiveStarDanfangArrayState();
}

class _FiveStarDanfangArrayState extends State<FiveStarDanfangArray>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double stoppedAngle = 0.0;
  List<Offset> lastOrbitPoints = [];
  bool isDisappearing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.isRunning) {
      _controller.repeat();
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant FiveStarDanfangArray oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 旋转控制
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
        stoppedAngle = _controller.value * 2 * math.pi;
      }
    }

    // 收回动画触发
    if (!widget.hasStarted && oldWidget.hasStarted) {
      final angle = widget.isRunning
          ? _controller.value * 2 * math.pi
          : stoppedAngle;
      final inner = widget.radius * 0.7;
      final outer = widget.radius * 0.9;
      final orbitRadius = (inner + outer) / 2;

      setState(() {
        isDisappearing = true;
        lastOrbitPoints = _calculateOrbitPoints(orbitRadius, angle);
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            isDisappearing = false;
            lastOrbitPoints = [];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Offset> _calculateOrbitPoints(double radius, double rotation) {
    const int points = 5;
    final angleOffset = -math.pi / 2;
    final step = 2 * math.pi / points;
    return List.generate(points, (i) {
      final angle = angleOffset + step * i + rotation;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      return Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final angle = widget.isRunning
            ? _controller.value * 2 * math.pi
            : stoppedAngle;

        final inner = widget.radius * 0.7;
        final outer = widget.radius * 0.9;
        final orbitRadius = (inner + outer) / 2;
        final orbitPoints = _calculateOrbitPoints(orbitRadius, angle);

        return SizedBox(
          width: widget.radius * 2 + widget.imageSize,
          height: widget.radius * 2 + widget.imageSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 五芒星图案
              CustomPaint(
                size: Size(widget.radius * 2, widget.radius * 2),
                painter: _FiveStarPainter(rotation: angle),
              ),

              // 中心丹炉（未开始或已收回）
              if (!widget.hasStarted && !isDisappearing)
                Image.asset(
                  widget.imagePath,
                  width: widget.imageSize * 2,
                  height: widget.imageSize * 2,
                ),

              // 开始炼丹：五个飞出丹炉
              if (widget.hasStarted)
                for (int i = 0; i < orbitPoints.length; i++)
                  TweenAnimationBuilder<Offset>(
                    tween: Tween<Offset>(
                      begin: Offset.zero,
                      end: orbitPoints[i],
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (_, offset, child) {
                      return Positioned(
                        left: widget.radius + offset.dx,
                        top: widget.radius + offset.dy,
                        child: child!,
                      );
                    },
                    child: Image.asset(
                      widget.imagePath,
                      width: widget.imageSize,
                      height: widget.imageSize,
                    ),
                  ),

              // 结束炼丹：五个丹炉飞回中心
              if (isDisappearing)
                for (int i = 0; i < lastOrbitPoints.length; i++)
                  TweenAnimationBuilder<Offset>(
                    tween: Tween<Offset>(
                      begin: lastOrbitPoints[i],
                      end: Offset.zero,
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInBack,
                    builder: (_, offset, child) {
                      return Positioned(
                        left: widget.radius + offset.dx,
                        top: widget.radius + offset.dy,
                        child: child!,
                      );
                    },
                    child: Image.asset(
                      widget.imagePath,
                      width: widget.imageSize,
                      height: widget.imageSize,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _FiveStarPainter extends CustomPainter {
  final List<String> symbols;
  final double outerRadiusRatio;
  final double innerRadiusRatio;
  final Color circleColor;
  final Color textColor;
  final double rotation;

  _FiveStarPainter({
    this.symbols = const ['✶', '卍', '₪', '☯', '※', 'Ω', '𓂀', '卐', '¤', '♒︎'],
    this.outerRadiusRatio = 0.9,
    this.innerRadiusRatio = 0.7,
    this.circleColor = Colors.orange,
    this.textColor = Colors.white,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = circleColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = size.width / 2 * outerRadiusRatio;
    final double innerRadius = size.width / 2 * innerRadiusRatio;

    // 加旋转
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // 圈圈
    canvas.drawCircle(center, outerRadius, paint);
    canvas.drawCircle(center, innerRadius, paint);

    // 五角星路径
    const int pointCount = 5;
    final double angleStep = 2 * math.pi / pointCount;
    final List<Offset> points = [];

    for (int i = 0; i < pointCount; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      points.add(Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      ));
    }

    final starPath = Path();
    for (int i = 0; i < pointCount; i++) {
      starPath.moveTo(points[i].dx, points[i].dy);
      starPath.lineTo(points[(i + 2) % pointCount].dx, points[(i + 2) % pointCount].dy);
    }
    canvas.drawPath(starPath, paint);

    // 符文
    final symbolCount = symbols.length;
    final double symbolRadius = (outerRadius + innerRadius) / 2;
    final double anglePerSymbol = 2 * math.pi / symbolCount;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontFamily: 'ZcoolCangEr',
    );

    for (int i = 0; i < symbolCount; i++) {
      final angle = -math.pi / 2 + i * anglePerSymbol;
      final Offset pos = Offset(
        center.dx + symbolRadius * math.cos(angle),
        center.dy + symbolRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: symbols[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    canvas.restore(); // 还原旋转
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
