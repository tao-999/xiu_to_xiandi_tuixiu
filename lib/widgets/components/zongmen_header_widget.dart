import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';

class ZongmenHeaderWidget extends StatelessWidget {
  final Zongmen zongmen;
  final VoidCallback? onUpgrade;

  const ZongmenHeaderWidget({
    super.key,
    required this.zongmen,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final level = zongmen.sectLevel;

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
              child: Row(
                children: [
                  Text(
                    'Lv $level',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orangeAccent,
                      fontFamily: 'ZcoolCangEr',
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (onUpgrade != null)
                    GestureDetector(
                      onTap: onUpgrade,
                      child: const Icon(Icons.add_circle_outline, size: 16, color: Colors.orangeAccent),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}