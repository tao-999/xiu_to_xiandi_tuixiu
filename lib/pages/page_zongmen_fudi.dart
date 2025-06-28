import 'package:flutter/material.dart';
import 'package:flame/game.dart';

// 👇 改成你实际路径
import '../widgets/components/back_button_overlay.dart';

class ZongmenFudiPage extends StatelessWidget {
  const ZongmenFudiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 加上封装好的返回组件
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
