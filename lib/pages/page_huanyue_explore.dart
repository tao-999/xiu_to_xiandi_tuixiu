import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floor_info_overlay.dart';
import '../widgets/components/huanyue_explore_game.dart';
import '../widgets/components/huanyue_reward_overlay.dart';

class HuanyueExplorePage extends StatefulWidget {
  const HuanyueExplorePage({super.key});

  @override
  State<HuanyueExplorePage> createState() => _HuanyueExplorePageState();
}

class _HuanyueExplorePageState extends State<HuanyueExplorePage> {
  late HuanyueExploreGame _game;

  /// 🚀 一劳永逸：只写一遍创建逻辑
  HuanyueExploreGame _createGame() {
    return HuanyueExploreGame(
      onReload: _reloadGame,
    );
  }

  @override
  void initState() {
    super.initState();
    _game = _createGame();
  }

  void _reloadGame() {
    setState(() {
      _game = _createGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'FloorInfo': (_, game) =>
                      FloorInfoOverlay(game: game as HuanyueExploreGame),
                  'Loading': (_, __) => const LoadingOverlay(),
                },
                initialActiveOverlays: const ['FloorInfo'],
              ),
            ),
            Positioned(
              top: 32,
              left: 12,
              child: RewardCounterOverlay(),
            ),
            const BackButtonOverlay(),
          ],
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
