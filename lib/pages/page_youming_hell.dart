import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/components/youming_hell_map_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class YoumingHellPage extends StatefulWidget {
  const YoumingHellPage({super.key});

  @override
  State<YoumingHellPage> createState() => _YoumingHellPageState();
}

class _YoumingHellPageState extends State<YoumingHellPage> {
  late YoumingHellMapGame game;

  @override
  void initState() {
    super.initState();
    game = YoumingHellMapGame(context, level: 1); // ✅ 实例化 game
  }

  @override
  void dispose() {
    final pos = game.player.position;
    print('📤 存档时玩家坐标：$pos');
    game.saveCurrentState(); // ✅ 页面销毁时强制存档
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(
            game: game,
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}