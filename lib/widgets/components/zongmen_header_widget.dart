// lib/widgets/components/zongmen_header_widget.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';

class ZongmenHeaderWidget extends StatelessWidget {
  final Zongmen zongmen;

  const ZongmenHeaderWidget({super.key, required this.zongmen});

  @override
  Widget build(BuildContext context) {
    final exp = zongmen.sectExp;
    final level = ZongmenStorage.calcSectLevel(exp);
    final currentLevelExp = ZongmenStorage.requiredExp(level);
    final nextLevelExp = ZongmenStorage.requiredExp(level + 1);
    final progress = ((exp - currentLevelExp) / (nextLevelExp - currentLevelExp)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              zongmen.name,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Lv $level',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.orangeAccent,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "经验：$exp / $nextLevelExp",
          style: const TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'ZcoolCangEr'),
        ),
      ],
    );
  }
}
