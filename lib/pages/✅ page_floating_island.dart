import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_distance_indicator.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_loader.dart';

class FloatingIslandPage extends StatefulWidget {
  const FloatingIslandPage({super.key});

  @override
  State<FloatingIslandPage> createState() => _FloatingIslandPageState();
}

class _FloatingIslandPageState extends State<FloatingIslandPage> {
  FloatingIslandMapComponent? _mapComponent;
  bool _hasSeed = false;

  @override
  void dispose() {
    _mapComponent?.saveState();
    _mapComponent?.onRemove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌟 地图
          if (_mapComponent != null)
            Positioned.fill(
              child: GameWidget(game: _mapComponent!),
            ),

          // 🌟 地图加载器
          if (!_hasSeed)
            FloatingIslandMapLoader(
              onSeedReady: (seed) {
                setState(() {
                  _hasSeed = true;
                  _mapComponent = FloatingIslandMapComponent(seed: seed);
                });
              },
            ),

          // 🌟 工具按钮
          if (_mapComponent != null) ...[
            Positioned(
              top: 40,
              left: 0,
              child: PlayerDistanceIndicator(mapComponent: _mapComponent!),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.white),
                onPressed: () {
                  // 🚀 定位到角色
                  _mapComponent!.centerOnPlayer();
                },
              ),
            ),
          ],

          // 🌟 返回按钮
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
