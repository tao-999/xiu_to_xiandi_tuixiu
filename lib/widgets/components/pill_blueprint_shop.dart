import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_blueprint_service.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import '../../models/resources.dart';
import '../../services/resources_storage.dart';
import '../common/toast_tip.dart';

class PillBlueprintShop extends StatelessWidget {
  const PillBlueprintShop({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDialog(context),
      child: Image.asset(
        'assets/images/sign_pill_shop.png',
        width: 120,
        height: 120,
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const _PillBlueprintDialogContent(),
      ),
    );
  }
}

class _PillBlueprintDialogContent extends StatefulWidget {
  const _PillBlueprintDialogContent({super.key});

  @override
  State<_PillBlueprintDialogContent> createState() => _PillBlueprintDialogContentState();
}

class _PillBlueprintDialogContentState extends State<_PillBlueprintDialogContent> {
  late List<PillBlueprint> all;
  Set<String> ownedKeys = {};
  Resources? _cachedResources;

  @override
  void initState() {
    super.initState();
    all = PillBlueprintService.generateAllBlueprints();
    _load();
  }

  Future<void> _load() async {
    ownedKeys = await PillBlueprintService.getPillBlueprintKeys();
    _cachedResources = await ResourcesStorage.load();
    setState(() {});
  }

  Future<void> _buy(PillBlueprint bp) async {
    final price = PillBlueprintService.getBlueprintPrice(bp.level);
    final balance = ResourcesStorage.getStoneAmount(_cachedResources!, price.type);

    if (balance < BigInt.from(price.amount)) {
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

    final field = lingShiFieldMap[price.type]!;
    await ResourcesStorage.subtract(field, BigInt.from(price.amount));
    await PillBlueprintService.addPillBlueprintKey(bp);

    ToastTip.show(context, '成功购买「${bp.name}」');
    await _load();
  }

  String _buildEffectText(PillBlueprint bp) {
    return '${bp.typeLabel} +${formatAnyNumber(bp.effectValue)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedResources == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = <int, List<PillBlueprint>>{};
    for (final bp in all) {
      grouped.putIfAbsent(bp.level, () => []).add(bp);
    }

    return SizedBox(
      width: 500,
      height: 720,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('丹方图纸商店', style: TextStyle(fontSize: 15, color: Colors.black87)),
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
                    final owned = ownedKeys.contains(bp.uniqueKey);
                    final price = PillBlueprintService.getBlueprintPrice(bp.level);
                    final balance = ResourcesStorage.getStoneAmount(_cachedResources!, price.type);
                    final affordable = balance >= BigInt.from(price.amount);
                    final canBuy = !owned && affordable;

                    return GestureDetector(
                      onTap: () {
                        if (owned) return;
                        if (!affordable) {
                          ToastTip.show(context, '${lingShiNames[price.type]}不足，无法购买');
                          return;
                        }
                        _buy(bp);
                      },
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
                            Opacity(
                              opacity: owned ? 0.4 : 1.0,
                              child: Image.asset(
                                'assets/images/${bp.iconPath}',
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
                            const SizedBox(height: 2),
                            Text(
                              owned
                                  ? '已拥有'
                                  : '${formatAnyNumber(price.amount)} ${lingShiNames[price.type]}',
                              style: TextStyle(
                                fontSize: 8,
                                color: owned
                                    ? Colors.grey
                                    : (affordable ? Colors.green : Colors.redAccent),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!owned) ...[
                              const SizedBox(height: 2),
                              Text(
                                _buildEffectText(bp),
                                style: const TextStyle(fontSize: 8, color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
}
