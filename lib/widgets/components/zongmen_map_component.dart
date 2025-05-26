import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_map_game.dart';

class ZongmenMapComponent extends StatelessWidget {
  const ZongmenMapComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: SectMapGame(),
    );
  }
}
