import 'package:flutter/material.dart';

import 'huanyue_explore_game.dart';

class FloorInfoOverlay extends StatelessWidget {
  final HuanyueExploreGame game;

  const FloorInfoOverlay({Key? key, required this.game}) : super(key: key);

  void _showInfoDialog(BuildContext context) {
    bool showTranslation = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFF9F5E3),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '幻月封妖地，苍茫锁禁渊。\n'
                          '五层藏秘宝，层进敌愈强。\n'
                          '凶险潜深处，机缘在险旁。\n'
                          '修行须慎步，莫负此仙章。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showTranslation)
                      const Text(
                        '📜 沙雕译文：\n'
                            '这是个程序自动生成的无限探索副本。\n'
                            '五层一套，掉落超棒，命悬一线但欧皇狂喜！\n'
                            '谨慎探索，不然掉坑打不过别怪我没提醒你～',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => setState(() {
                        showTranslation = !showTranslation;
                      }),
                      child: Text(
                        showTranslation ? '收起翻译' : '点我翻译 📖',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.none, // ✅ 强制去掉下划线
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
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
