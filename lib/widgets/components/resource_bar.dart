import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

import '../../utils/lingshi_util.dart';

class ResourceBar extends StatefulWidget {
  const ResourceBar({super.key});

  @override
  ResourceBarState createState() => ResourceBarState();
}

class ResourceBarState extends State<ResourceBar> {
  BigInt low = BigInt.zero;
  BigInt mid = BigInt.zero;
  BigInt high = BigInt.zero;
  BigInt supreme = BigInt.zero;
  int charm = 0;
  int recruitTicket = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// 🌟 对外暴露的刷新方法（外部可用 key.currentState?.refresh() 调用）
  Future<void> refresh() async {
    setState(() {
      loading = true;
    });
    low = await ResourcesStorage.getValue('spiritStoneLow');
    mid = await ResourcesStorage.getValue('spiritStoneMid');
    high = await ResourcesStorage.getValue('spiritStoneHigh');
    supreme = await ResourcesStorage.getValue('spiritStoneSupreme');
    charm = (await ResourcesStorage.getValue('fateRecruitCharm')).toInt();
    recruitTicket = (await ResourcesStorage.getValue('recruitTicket')).toInt();

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(height: 48); // 顶部固定高度
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildItem('下品灵石', low, getLingShiImagePath(LingShiType.lower)),
                const SizedBox(width: 16),
                _buildItem('中品灵石', mid, getLingShiImagePath(LingShiType.middle)),
                const SizedBox(width: 16),
                _buildItem('上品灵石', high, getLingShiImagePath(LingShiType.upper)),
                const SizedBox(width: 16),
                _buildItem('极品灵石', supreme, getLingShiImagePath(LingShiType.supreme)),
                const SizedBox(width: 16),
                _buildItem('资质提升券', charm, 'assets/images/fate_recruit_charm.png'),
                const SizedBox(width: 16),
                _buildItem('招募券', recruitTicket, 'assets/images/recruit_ticket.png'),
              ],
            ),
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
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 4),
        Text(
          formatted,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
      ],
    );
  }
}
