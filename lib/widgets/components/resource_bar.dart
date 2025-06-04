import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';

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
        decoration: BoxDecoration(
          color: const Color(0xFFF8F0E3),
          border: const Border(bottom: BorderSide(color: Colors.brown, width: 0.5)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildItem('下品灵石', formatLargeNumber(res.spiritStoneLow), Icons.circle),
              const SizedBox(width: 16),
              _buildItem('中品灵石', formatLargeNumber(res.spiritStoneMid), Icons.change_history),
              const SizedBox(width: 16),
              _buildItem('上品灵石', formatLargeNumber(res.spiritStoneHigh), Icons.diamond),
              const SizedBox(width: 16),
              _buildItem('极品灵石', formatLargeNumber(res.spiritStoneSupreme), Icons.star),
              const SizedBox(width: 16),
              _buildItem('资质提升券', formatLargeNumber(res.fateRecruitCharm), Icons.school),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber[800]),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
