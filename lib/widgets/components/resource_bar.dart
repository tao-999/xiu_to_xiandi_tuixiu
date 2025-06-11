import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';

import '../../utils/number_format.dart';

class ResourceBar extends StatelessWidget {
  final Character player;

  const ResourceBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final res = player.resources;

    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F0E3),
          border: Border(
            bottom: BorderSide(color: Colors.brown, width: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildItem('下品灵石', res.spiritStoneLow, Icons.circle),
              const SizedBox(width: 16),
              _buildItem('中品灵石', res.spiritStoneMid, Icons.change_history),
              const SizedBox(width: 16),
              _buildItem('上品灵石', res.spiritStoneHigh, Icons.diamond),
              const SizedBox(width: 16),
              _buildItem('极品灵石', res.spiritStoneSupreme, Icons.star),
              const SizedBox(width: 16),
              _buildItem('资质提升券', res.fateRecruitCharm, Icons.school),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, dynamic value, IconData icon) {
    String formatted = formatAnyNumber(value);

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber[800]),
        const SizedBox(width: 4),
        Text(
          formatted,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
