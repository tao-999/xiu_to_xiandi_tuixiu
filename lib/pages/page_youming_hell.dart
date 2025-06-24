import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/components/hell_level_overlay.dart';
import '../widgets/components/youming_hell_map_game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

class YoumingHellPage extends StatelessWidget {
  const YoumingHellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int currentFloor = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(
            game: YoumingHellMapGame(context, level: currentFloor),
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          ),
          const BackButtonOverlay(),

          // ✅ 地狱层数标签
          Positioned(
            top: 0,
            right: 0,
            child: HellLevelOverlay(level: currentFloor),
          ),
        ],
      ),
    );
  }
}
