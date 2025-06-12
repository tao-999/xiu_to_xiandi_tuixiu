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
              _buildItem('下品灵石', res.spiritStoneLow, 'assets/images/spirit_stone_low.png'),
              const SizedBox(width: 16),
              _buildItem('中品灵石', res.spiritStoneMid, 'assets/images/spirit_stone_mid.png'),
              const SizedBox(width: 16),
              _buildItem('上品灵石', res.spiritStoneHigh, 'assets/images/spirit_stone_high.png'),
              const SizedBox(width: 16),
              _buildItem('极品灵石', res.spiritStoneSupreme, 'assets/images/spirit_stone_supreme.png'),
              const SizedBox(width: 16),
              _buildItem('资质提升券', res.fateRecruitCharm, 'assets/images/fate_recruit_charm.png'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, dynamic value, String imagePath) {
    String formatted = formatAnyNumber(value);

    return Row(
      children: [
        Image.asset(
          imagePath,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
        ),
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
