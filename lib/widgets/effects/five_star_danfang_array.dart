import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AlchemyPhase {
  idle,
  drawingStarPath,
  drawingInnerArc,
  drawingRunes,
  drawingOuterArc,
  done,
  reversing,
}

class FiveStarAlchemyArray extends StatefulWidget {
  final double radius;
  final double bigDanluSize;   // ✅ 中心丹炉大小
  final double smallDanluSize; // ✅ 飞出丹炉大小

  const FiveStarAlchemyArray({
    super.key,
    this.radius = 120,
    this.bigDanluSize = 90,
    this.smallDanluSize = 36,
  });

  @override
  FiveStarAlchemyArrayState createState() => FiveStarAlchemyArrayState();
}

class FiveStarAlchemyArrayState extends State<FiveStarAlchemyArray>
    with TickerProviderStateMixin {
  late AnimationController starController;
  late AnimationController arcController;
  late AnimationController runeController;
  late AnimationController outerController;
  late AnimationController flyController;
  late AnimationController floatController;
  late Animation<double> floatAnimation;

  AlchemyPhase phase = AlchemyPhase.idle;
  List<Animation<Offset>>? flyAnimations;
  bool hasFiredDanlu = false;

  @override
  void initState() {
    super.initState();

    starController = _ctrl(seconds: 1);
    arcController = _ctrl(milliseconds: 800);
    runeController = _ctrl(milliseconds: 800);
    outerController = _ctrl(milliseconds: 800);

    flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() => setState(() {}));

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));
  }

  AnimationController _ctrl({int seconds = 0, int milliseconds = 0}) {
    return AnimationController(
      vsync: this,
      duration: Duration(seconds: seconds, milliseconds: milliseconds),
    )..addListener(() => setState(() {}));
  }

  Future<void> start() async {
    setState(() {
      phase = AlchemyPhase.drawingStarPath;
      hasFiredDanlu = false;
    });

    await starController.forward(from: 0);
    setState(() => phase = AlchemyPhase.drawingInnerArc);

    await arcController.forward(from: 0);
    setState(() => phase = AlchemyPhase.drawingRunes);

    await runeController.forward(from: 0);
    setState(() => phase = AlchemyPhase.drawingOuterArc);

    await outerController.forward(from: 0);
    setState(() => phase = AlchemyPhase.done);

    _launchSmallDanlus();
    await flyController.forward(from: 0);
  }

  Future<void> stop() async {
    setState(() => phase = AlchemyPhase.reversing);
    await flyController.reverse(from: 1.0);
    setState(() => hasFiredDanlu = false);

    await outerController.reverse(from: 1.0);
    await runeController.reverse(from: 1.0);
    await arcController.reverse(from: 1.0);
    await starController.reverse(from: 1.0);
    setState(() => phase = AlchemyPhase.idle);
  }

  void _launchSmallDanlus() {
    final r = widget.radius * 0.78;
    flyAnimations = List.generate(5, (i) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final target = Offset(r * math.cos(angle), r * math.sin(angle));
      return Tween<Offset>(begin: Offset.zero, end: target).animate(
        CurvedAnimation(parent: flyController, curve: Curves.easeOut),
      );
    });
    hasFiredDanlu = true;
  }

  @override
  void dispose() {
    starController.dispose();
    arcController.dispose();
    runeController.dispose();
    outerController.dispose();
    flyController.dispose();
    floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _AlchemyPainter(
              radius: widget.radius,
              phase: phase,
              starProgress: starController.value,
              arcProgress: arcController.value,
              runeProgress: runeController.value,
              outerProgress: outerController.value,
            ),
            size: Size.square(widget.radius * 2),
          ),

          // 🏺 中心大丹炉
          if (!hasFiredDanlu || phase == AlchemyPhase.reversing)
            Image.asset(
              'assets/images/zongmen_liandanlu.png',
              width: widget.bigDanluSize,
              height: widget.bigDanluSize,
            ),

          // 🏺 小丹炉（上下浮动）
          if (hasFiredDanlu && flyAnimations != null)
            ...List.generate(5, (i) {
              final anim = flyAnimations![i].value;
              final offset = Offset(anim.dx, anim.dy + floatAnimation.value);
              return Transform.translate(
                offset: offset,
                child: Image.asset(
                  'assets/images/zongmen_liandanlu.png',
                  width: widget.smallDanluSize,
                  height: widget.smallDanluSize,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AlchemyPainter extends CustomPainter {
  final double radius;
  final AlchemyPhase phase;
  final double starProgress;
  final double arcProgress;
  final double runeProgress;
  final double outerProgress;

  _AlchemyPainter({
    required this.radius,
    required this.phase,
    required this.starProgress,
    required this.arcProgress,
    required this.runeProgress,
    required this.outerProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerR = radius * 0.6;
    final outerR = radius * 0.9;
    final middleR = (innerR + outerR) / 2;

    final points = List.generate(5, (i) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      return Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
    });

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    int index = 0;
    for (int i = 0; i < 5; i++) {
      index = (index + 2) % 5;
      path.lineTo(points[index].dx, points[index].dy);
    }
    path.close();

    if (phase.index >= AlchemyPhase.drawingStarPath.index) {
      final metric = path.computeMetrics().first;
      final extract = metric.extractPath(0, metric.length * starProgress);
      canvas.drawPath(extract, paint);
    }

    if (phase.index >= AlchemyPhase.drawingInnerArc.index) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerR),
        -math.pi / 2,
        2 * math.pi * arcProgress,
        false,
        paint,
      );
    }

    if (phase.index >= AlchemyPhase.drawingRunes.index) {
      final symbols = ['✶', 'Ω', '卍', '₪', '☯', '※', '𓂀', '♒︎'];
      final textStyle = TextStyle(color: Colors.white, fontSize: 14);
      for (int i = 0; i < (symbols.length * runeProgress).floor(); i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / symbols.length;
        final pos = Offset(
          center.dx + middleR * math.cos(angle),
          center.dy + middleR * math.sin(angle),
        );
        final tp = TextPainter(
          text: TextSpan(text: symbols[i], style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
      }
    }

    if (phase.index >= AlchemyPhase.drawingOuterArc.index) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerR),
        -math.pi / 2,
        2 * math.pi * outerProgress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AlchemyPainter old) =>
      starProgress != old.starProgress ||
          arcProgress != old.arcProgress ||
          runeProgress != old.runeProgress ||
          outerProgress != old.outerProgress ||
          phase != old.phase;
}
