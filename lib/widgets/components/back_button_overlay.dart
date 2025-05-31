import 'package:flutter/material.dart';

class BackButtonOverlay extends StatelessWidget {
  const BackButtonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Image.asset(
            'assets/images/back.png', // 确保你放在了 assets/images/ 目录
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
