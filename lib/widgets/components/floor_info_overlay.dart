import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_huanyue_explore.dart';

class FloorInfoOverlay extends StatelessWidget {
  final HuanyueExploreGame game;

  const FloorInfoOverlay({Key? key, required this.game}) : super(key: key);

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const Text(
            '幻月封妖地，苍茫锁禁渊。\n'
                '五层藏秘宝，层进敌愈强。\n'
                '凶险潜深处，机缘在险旁。\n'
                '修行须慎步，莫负此仙章。',
            textAlign: TextAlign.center, // ✅ 就这句！关键！
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<int>(
              stream: game.floorStream,
              initialData: game.currentFloor,
              builder: (context, snapshot) {
                final floor = snapshot.data ?? game.currentFloor;
                return Text(
                  '第 $floor 层',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 14,
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showInfoDialog(context),
              child: const Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
