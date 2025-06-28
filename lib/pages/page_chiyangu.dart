import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/chiyangu_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/pickaxe_overlay.dart';

import '../widgets/components/depth_and_reward_info.dart';

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

          // ✅ GameWidget（自动撑满下半屏）
          Positioned(
            top: screenHeight / 2,
            left: 0,
            right: 0,
            height: screenHeight / 2,
            child: GameWidget(game: _game),
          ),

          // ✅ 上半部分遮罩图
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

          // ✅ 深度信息
          Positioned(
            top: 16,
            left: 16,
            child: DepthAndRewardInfo(),
          ),

          // ✅ 锄头 UI
          const PickaxeOverlay(),

          // ✅ 返回按钮（最上层）
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
