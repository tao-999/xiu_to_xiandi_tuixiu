import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

import '../../models/resources.dart';
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
  const _BlueprintDialogContent({super.key});

  @override
  State<_BlueprintDialogContent> createState() => _BlueprintDialogContentState();
}

class _BlueprintDialogContentState extends State<_BlueprintDialogContent> {
  late List<RefineBlueprint> all;
  late Resources res;
  Set<String> ownedKeys = {};

  @override
  void initState() {
    super.initState();
    all = RefineBlueprintService.generateAllBlueprints();
    _load();
  }

  Future<void> _load() async {
    res = await ResourcesStorage.load();
    ownedKeys = await ResourcesStorage.getBlueprintKeys();
    setState(() {});
  }

  Future<void> _buy(RefineBlueprint bp) async {
    final price = RefineBlueprintService.getBlueprintPrice(bp.level);
    final field = lingShiFieldMap[price.type]!;
    final balance = ResourcesStorage.getStoneAmount(res, price.type);

    if (balance < price.amount) {
      ToastTip.show(context, '${lingShiNames[price.type]}不足，无法购买');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Text(
          '是否花费 ${formatAnyNumber(price.amount)} ${lingShiNames[price.type]} 购买「${bp.name}」？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ResourcesStorage.subtract(field, price.amount);
    await ResourcesStorage.addBlueprintKey(bp);

    ToastTip.show(context, '成功购买「${bp.name}」');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<RefineBlueprint>>{};
    for (final bp in all) {
      grouped.putIfAbsent(bp.level, () => []).add(bp);
    }

    return SizedBox(
      width: 360,
      height: 480,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              '装备图纸商店',
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${entry.key}阶', style: const TextStyle(fontSize: 12)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: entry.value.map((bp) {
                    final owned = ownedKeys.contains('${bp.type.name}-${bp.level}');
                    final price = RefineBlueprintService.getBlueprintPrice(bp.level);
                    final balance = ResourcesStorage.getStoneAmount(res, price.type);
                    final affordable = balance >= price.amount;

                    return GestureDetector(
                      onTap: owned ? null : () => _buy(bp),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: const Border(
                            right: BorderSide(color: Colors.black12),
                            bottom: BorderSide(color: Colors.black12),
                          ),
                          color: owned ? Colors.grey.shade300 : Colors.white,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bp.iconPath != null)
                              Opacity(
                                opacity: owned ? 0.4 : 1.0,
                                child: Image.asset(
                                  'assets/images/${bp.iconPath!}',
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported, size: 24),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              bp.name.split('·').first,
                              style: TextStyle(
                                fontSize: 10,
                                color: owned ? Colors.grey : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            if (bp.attackBoost > 0 || bp.defenseBoost > 0 || bp.healthBoost > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  _buildBoostText(bp),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Text(
                              owned
                                  ? '已拥有'
                                  : '${formatAnyNumber(price.amount)} ${lingShiNames[price.type]}',
                              style: TextStyle(
                                fontSize: 8,
                                color: owned
                                    ? Colors.grey
                                    : (affordable ? Colors.green : Colors.red),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  String _buildBoostText(RefineBlueprint bp) {
    final parts = <String>[];
    if (bp.attackBoost > 0) parts.add('+${bp.attackBoost}% 攻击');
    if (bp.defenseBoost > 0) parts.add('+${bp.defenseBoost}% 防御');
    if (bp.healthBoost > 0) parts.add('+${bp.healthBoost}% 血量');
    return parts.join('  ');
  }
}
