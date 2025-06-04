// 📂 lib/widgets/components/floor_info_overlay.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_huanyue_explore.dart';

class FloorInfoOverlay extends StatelessWidget {
  final HuanyueExploreGame game;

  const FloorInfoOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 6,
            )
          ],
        ),
        child: StreamBuilder<int>(
          stream: game.floorStream,
          initialData: game.currentFloor,
          builder: (context, snapshot) {
            final floor = snapshot.data ?? game.currentFloor;
            return Text(
              '第 $floor 层',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
