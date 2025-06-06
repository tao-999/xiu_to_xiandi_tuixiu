import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/chiyangu_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pickaxe_overlay.dart';

class ChiyanguPage extends StatefulWidget {
  const ChiyanguPage({super.key});

  @override
  State<ChiyanguPage> createState() => _ChiyanguPageState();
}

class _ChiyanguPageState extends State<ChiyanguPage> {
  late final ChiyanguGame _game;

  @override
  void initState() {
    super.initState();
    _game = ChiyanguGame(); // ✅ 实例化游戏
  }

  @override
  void dispose() {
    _game.saveCurrentState(); // ✅ 页面退出时保存状态
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final gameWidth = ChiyanguGame.cols * ChiyanguGame.cellSize;
    final gameLeft = (screenWidth - gameWidth) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ 背景图（全屏）
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_chiyangu.webp',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ GameWidget 放在下半部分中央
          Positioned(
            top: screenHeight / 2,
            left: gameLeft,
            width: gameWidth,
            height: screenHeight / 2,
            child: GameWidget(game: _game),
          ),

          // ✅ 上半遮罩层（lava 图上半部分）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight / 2,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/bg_chiyangu.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // ✅ 深度显示组件（右上角）
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder<int>(
              valueListenable: ChiyanguGame.depthNotifier,
              builder: (context, value, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '深度：$value 米',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ 锄头显示组件（左上角）
          const PickaxeOverlay(),

          // ✅ 返回按钮（放最上层）
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
