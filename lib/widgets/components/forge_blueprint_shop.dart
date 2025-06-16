import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

import '../../models/resources.dart';
import '../../services/resources_storage.dart';
import '../common/toast_tip.dart';

class ForgeBlueprintShop extends StatelessWidget {
  const ForgeBlueprintShop({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBlueprintShopDialog(context),
      child: Image.asset(
        'assets/images/sign_weapon_shop.png',
        width: 80,
        height: 80,
      ),
    );
  }

  void _showBlueprintShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const _BlueprintDialogContent(),
      ),
    );
  }
}

class _BlueprintDialogContent extends StatefulWidget {
  const _BlueprintDialogContent();

  @override
  State<_BlueprintDialogContent> createState() => _BlueprintDialogContentState();
}

class _BlueprintDialogContentState extends State<_BlueprintDialogContent> {
  late Future<Resources> _futureRes;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _futureRes = ResourcesStorage.load();
  }

  void _refresh() {
    setState(() {
      _futureRes = ResourcesStorage.load();
      // ❌ 不再自动滚动，只在首次构建时滚
    });
  }

  @override
  Widget build(BuildContext context) {
    final allBlueprints = RefineBlueprintService.generateAllBlueprints();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
          child: Text(
            '⚒️ 武器图纸商店',
            style: TextStyle(
              fontSize: 20,
              color: Colors.deepOrangeAccent,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.brown),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<Resources>(
              future: _futureRes,
              builder: (context, snapshot) {
                final res = snapshot.data;
                if (res == null) return const Text('加载中...');

                // ✅ 首次滚动到第一个未购买的图纸
                if (!_hasScrolled) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final index = allBlueprints.indexWhere(
                          (b) => !res.ownedBlueprintKeys.contains('${b.type.name}-${b.level}'),
                    );
                    if (index >= 0) {
                      final offset = index * 110.0;
                      _scrollController.jumpTo(offset);
                    }
                    _hasScrolled = true;
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: RefineBlueprintService.maxLevel,
                  itemBuilder: (context, levelIndex) {
                    final level = levelIndex + 1;
                    final levelBlueprints = allBlueprints
                        .where((b) => b.level == level)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📛 ${level}阶',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...levelBlueprints.map((b) => _buildBlueprintItem(context, b, res)).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlueprintItem(BuildContext context, RefineBlueprint blueprint, Resources res) {
    final effect = RefineBlueprintService.getEffectMeta(blueprint);
    final price = RefineBlueprintService.getBlueprintPrice(blueprint.level);
    final key = '${blueprint.type.name}-${blueprint.level}';

    final isOwned = res.ownedBlueprintKeys.contains(key);
    final userAmount = switch (price.type) {
      LingShiType.lower => res.spiritStoneLow,
      LingShiType.middle => res.spiritStoneMid,
      LingShiType.high => res.spiritStoneHigh,
      LingShiType.supreme => res.spiritStoneSupreme,
    };
    final isEnough = userAmount >= price.amount;

    final String priceText =
        '价格：${_getLingShiTypeName(price.type)} × ${formatAnyNumber(price.amount)}';

    final priceColor = isOwned
        ? Colors.grey
        : isEnough
        ? Colors.green
        : Colors.redAccent;

    final effectText = effect['type'].isNotEmpty ? '${effect['type']} +${effect['value']}%' : '无';

    final content = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown.shade300),
        color: isOwned ? Colors.grey.shade200 : Colors.white,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/${blueprint.iconPath ?? 'default_icon.png'}',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            color: isOwned ? Colors.grey : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blueprint.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOwned ? Colors.grey : const Color(0xFF2E1C0C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '效果：$effectText',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  priceText,
                  style: TextStyle(fontSize: 13, color: priceColor),
                ),
                if (isOwned)
                  const Text('✅ 已拥有', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );

    if (isOwned) return content;

    return GestureDetector(
      onTap: () {
        if (!isEnough) {
          final name = _getLingShiTypeName(price.type);
          ToastTip.show(context, '$name不足，无法购买');
          return;
        }

        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: const Color(0xFFF9F5E3),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '你将花费 $priceText\n是否继续购买？',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);

                      final field = switch (price.type) {
                        LingShiType.lower => 'spiritStoneLow',
                        LingShiType.middle => 'spiritStoneMid',
                        LingShiType.high => 'spiritStoneHigh',
                        LingShiType.supreme => 'spiritStoneSupreme',
                      };

                      await ResourcesStorage.subtract(field, price.amount);
                      await ResourcesStorage.addBlueprintKey(blueprint);
                      ToastTip.show(context, '购买成功 ✅');
                      _refresh();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.brown, size: 18),
                        SizedBox(width: 6),
                        Text('确认购买', style: TextStyle(fontSize: 13, color: Colors.brown)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: content,
    );
  }

  String _getLingShiTypeName(LingShiType type) {
    switch (type) {
      case LingShiType.lower:
        return '下品灵石';
      case LingShiType.middle:
        return '中品灵石';
      case LingShiType.high:
        return '上品灵石';
      case LingShiType.supreme:
        return '极品灵石';
    }
  }
}
