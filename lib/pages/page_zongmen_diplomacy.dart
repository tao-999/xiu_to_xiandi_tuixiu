import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../widgets/components/back_button_overlay.dart';
import '../widgets/components/zongmen_diplomacy_map_component.dart';
import '../widgets/components/locate_player_Icon.dart';

class ZongmenDiplomacyPage extends StatefulWidget {
  const ZongmenDiplomacyPage({Key? key}) : super(key: key);

  @override
  State<ZongmenDiplomacyPage> createState() => _ZongmenDiplomacyPageState();
}

class _ZongmenDiplomacyPageState extends State<ZongmenDiplomacyPage> {
  // 用来获取game实例
  final ZongmenDiplomacyMapComponent _game = ZongmenDiplomacyMapComponent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(
            game: _game,
          ),
          const BackButtonOverlay(),
          LocatePlayerIcon(
            onLocate: () {
              _game.centerViewOnPlayer();
            },
          ),
        ],
      ),
    );
  }
}
