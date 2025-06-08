// 📄 lib/widgets/components/recruit_illustration_widget.dart
import 'package:flutter/material.dart';

class RecruitIllustrationWidget extends StatelessWidget {
  final String pool;

  const RecruitIllustrationWidget({
    super.key,
    required this.pool,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = pool == 'human'
        ? 'assets/images/human_recruitment_background.png'
        : 'assets/images/immortal_recruitment_background.png';

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
              Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
