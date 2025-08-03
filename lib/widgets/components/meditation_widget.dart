import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MeditationWidget extends StatefulWidget {
  final String imagePath;
  final bool ready;
  final Animation<Offset> offset;
  final Animation<double> opacity;
  final DateTime createdAt;

  const MeditationWidget({
    super.key,
    required this.imagePath,
    required this.ready,
    required this.offset,
    required this.opacity,
    required this.createdAt,
  });

  @override
  State<MeditationWidget> createState() => _MeditationWidgetState();
}

class _MeditationWidgetState extends State<MeditationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<Offset> _floatOffset;

  LottieComposition? _composition;
  late Timer _timer;
  final ValueNotifier<Duration> _elapsedNotifier = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.02),
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // 预加载 Lottie 动画
    _loadComposition();

    // 初始化时间
    _elapsedNotifier.value = DateTime.now().difference(widget.createdAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedNotifier.value = DateTime.now().difference(widget.createdAt);
    });
  }

  Future<void> _loadComposition() async {
    final comp = await AssetLottie('assets/animations/spirit_smoke.json').load();
    setState(() {
      _composition = comp;
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _timer.cancel();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 灵气特效（左右对称）
        if (_composition != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAura(mirror: false),
              const SizedBox(width: 10),
              _buildAura(mirror: true),
            ],
          ),

        // 修士人物 + 状态
        !widget.ready
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: widget.offset,
              child: FadeTransition(
                opacity: widget.opacity,
                child: SlideTransition(
                  position: _floatOffset,
                  child: Image.asset(
                    widget.imagePath,
                    width: 60,
                    height: 72,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAura({required bool mirror}) {
    final transform = Matrix4.identity();
    if (mirror) transform.scale(-1.0, 1.0);

    return SizedBox(
      width: 50,
      height: 50,
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: Transform.scale(
          scale: 1,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.srcIn,
            ),
            child: Lottie(
              composition: _composition!,
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
