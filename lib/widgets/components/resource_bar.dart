import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
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
    // 如果是 BigInt 类型，转换为 double；如果是 int，先转为 BigInt 后再转换为 double
    num displayValue = value is BigInt ? value.toDouble() : value is int ? BigInt.from(value).toDouble() : value;

    // 传给 formatLargeNumber 后会变成统一的 num 类型，避免类型冲突
    String formatted = formatLargeNumber(displayValue);

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
