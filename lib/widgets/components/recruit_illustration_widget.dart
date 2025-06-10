import 'dart:async';
import 'package:flutter/material.dart';

class RecruitIllustrationWidget extends StatefulWidget {
  final String pool;

  const RecruitIllustrationWidget({
    super.key,
    required this.pool,
  });

  @override
  State<RecruitIllustrationWidget> createState() => _RecruitIllustrationWidgetState();
}

class _RecruitIllustrationWidgetState extends State<RecruitIllustrationWidget>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _currentIndex = 0;
  final Duration _interval = const Duration(seconds: 15);
  final Duration _fadeDuration = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();

    if (widget.pool == 'human') {
      _timer = Timer.periodic(_interval, (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % 2;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = widget.pool == 'human'
        ? [
      'assets/images/human_recruitment_background.png',
      'assets/images/human_recruitment_background2.png',
    ]
        : [
      'assets/images/immortal_recruitment_background.png',
    ];

    return Transform.translate(
      offset: const Offset(0, -60),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 400,
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 20,
                child: Container(
                  width: 260,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // 淡入淡出图层
              ...List.generate(imagePaths.length, (index) {
                return AnimatedOpacity(
                  duration: _fadeDuration,
                  opacity: _currentIndex == index ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    imagePaths[index],
                    fit: BoxFit.contain,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
