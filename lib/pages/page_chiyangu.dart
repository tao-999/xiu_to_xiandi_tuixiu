import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/chiyangu_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class ChiyanguPage extends StatelessWidget {
  const ChiyanguPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final gameWidth = ChiyanguGame.cols * ChiyanguGame.cellSize;
    final gameLeft = (screenWidth - gameWidth) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ GameWidget 放在屏幕中央下半部分
          Positioned(
            top: screenHeight / 2,
            left: gameLeft,
            width: gameWidth,
            height: screenHeight / 2,
            child: GameWidget(game: ChiyanguGame()),
          ),

          // ✅ 黑色遮罩覆盖上半屏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight / 2,
            child: IgnorePointer(
              child: Container(
                color: Colors.black,
              ),
            ),
          ),

          // ✅ 返回按钮在最上层
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
