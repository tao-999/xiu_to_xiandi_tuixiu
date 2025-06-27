import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_distance_indicator.dart'; // 加载距离显示组件

class FloatingIslandPage extends StatefulWidget {
  const FloatingIslandPage({super.key});

  @override
  State<FloatingIslandPage> createState() => _FloatingIslandPageState();
}

class _FloatingIslandPageState extends State<FloatingIslandPage> {
  late final FloatingIslandMapComponent _mapComponent;

  @override
  void initState() {
    super.initState();
    _mapComponent = FloatingIslandMapComponent();
  }

  @override
  void dispose() {
    _mapComponent.saveState();     // ⬅️ 先保存
    _mapComponent.onRemove();      // ⬅️ 再清理
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _mapComponent),

          // 📍 左上角角色距离显示
          Positioned(
            top: 40,
            left: 20,
            child: PlayerDistanceIndicator(mapComponent: _mapComponent),
          ),

          // 📍 右上角定位按钮
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () {
                _mapComponent.resetToCenter();
              },
            ),
          ),

          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
