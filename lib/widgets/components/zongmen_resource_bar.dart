// lib/widgets/components/zongmen_resource_bar.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';

class ZongmenResourceBar extends StatelessWidget {
  final Zongmen zongmen;

  const ZongmenResourceBar({super.key, required this.zongmen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resItem("下品灵石", zongmen.spiritStoneLow),
          _resItem("中品灵石", zongmen.spiritStoneMid),
          _resItem("上品灵石", zongmen.spiritStoneHigh),
          _resItem("极品灵石", zongmen.spiritStoneSupreme),
        ],
      ),
    );
  }

  Widget _resItem(String name, int value) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'ZcoolCangEr',
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$value",
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
      ],
    );
  }
}
