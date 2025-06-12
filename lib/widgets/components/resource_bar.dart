import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

class ResourceBar extends StatefulWidget {
  const ResourceBar({super.key});

  @override
  State<ResourceBar> createState() => _ResourceBarState();
}

class _ResourceBarState extends State<ResourceBar> {
  BigInt low = BigInt.zero;
  BigInt mid = BigInt.zero;
  BigInt high = BigInt.zero;
  BigInt supreme = BigInt.zero;
  int charm = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    low = await ResourcesStorage.getValue('spiritStoneLow');
    mid = await ResourcesStorage.getValue('spiritStoneMid');
    high = await ResourcesStorage.getValue('spiritStoneHigh');
    supreme = await ResourcesStorage.getValue('spiritStoneSupreme');
    charm = (await ResourcesStorage.getValue('fateRecruitCharm')).toInt();

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    if (loading) {
      return SizedBox(height: topInset + 48); // 占位，避免跳动
    }

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
              _buildItem('下品灵石', low, 'assets/images/spirit_stone_low.png'),
              const SizedBox(width: 16),
              _buildItem('中品灵石', mid, 'assets/images/spirit_stone_mid.png'),
              const SizedBox(width: 16),
              _buildItem('上品灵石', high, 'assets/images/spirit_stone_high.png'),
              const SizedBox(width: 16),
              _buildItem('极品灵石', supreme, 'assets/images/spirit_stone_supreme.png'),
              const SizedBox(width: 16),
              _buildItem('资质提升券', charm, 'assets/images/fate_recruit_charm.png'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, dynamic value, String imagePath) {
    final formatted = formatAnyNumber(value);

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
