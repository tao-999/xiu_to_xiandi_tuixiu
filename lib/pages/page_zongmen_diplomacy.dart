import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/zongmen_diplomacy_map_component.dart';

class ZongmenDiplomacyPage extends StatelessWidget {
  const ZongmenDiplomacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(
            game: ZongmenDiplomacyMapComponent(),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
