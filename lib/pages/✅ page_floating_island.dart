import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_map_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _mapComponent),

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
