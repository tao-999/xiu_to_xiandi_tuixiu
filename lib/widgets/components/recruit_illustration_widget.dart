// lib/widgets/components/recruit_illustration_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class RecruitIllustrationWidget extends StatefulWidget {
  const RecruitIllustrationWidget({
    super.key,
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

  final List<String> _imagePaths = [
    'assets/images/human_recruitment_background.png',
    'assets/images/human_recruitment_background2.png',
  ];

  @override
  void initState() {
    super.initState();
    // 固定每15秒切换背景图
    _timer = Timer.periodic(_interval, (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _imagePaths.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 固定淡入淡出效果
              ...List.generate(_imagePaths.length, (index) {
                return AnimatedOpacity(
                  duration: _fadeDuration,
                  opacity: _currentIndex == index ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    _imagePaths[index],
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
