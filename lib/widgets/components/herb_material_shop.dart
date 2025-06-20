import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/herb_material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/herb_material_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import '../../models/resources.dart';
import '../common/toast_tip.dart';
import '../../utils/number_format.dart';

class HerbMaterialShop extends StatelessWidget {
  const HerbMaterialShop({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShopDialog(context),
      child: Image.asset(
        'assets/images/xianyao_shop.png',
        width: 80,
        height: 80,
      ),
    );
  }

  void _showShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const _HerbShopContent(),
      ),
    );
  }
}

class _HerbShopContent extends StatefulWidget {
  const _HerbShopContent({super.key});

  @override
  State<_HerbShopContent> createState() => _HerbShopContentState();
}

class _HerbShopContentState extends State<_HerbShopContent> {
  late List<HerbMaterial> herbs;
  Map<String, int>? owned; // ✅ 改为可空
  late Resources res;

  @override
  void initState() {
    super.initState();
    herbs = HerbMaterialService.generateAllMaterials();
    _loadData();
  }

  Future<void> _loadData() async {
    res = await ResourcesStorage.load();
    final counts = <String, int>{};

    for (final herb in herbs) {
      final count = await HerbMaterialService.getCount(herb.name);
      counts[herb.name] = count;
    }

    setState(() {
      owned = counts;
    });
  }

  Future<void> _buy(HerbMaterial herb) async {
    final unitPrice = BigInt.from(herb.priceAmount);
    final type = herb.priceType;
    final field = lingShiFieldMap[type]!;
    final balance = ResourcesStorage.getStoneAmount(res, type);

    int quantity = 1;
    Timer? _timer;

    void startHold(VoidCallback cb) {
      cb();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => cb());
    }

    void stopHold() {
      _timer?.cancel();
      _timer = null;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalPrice = unitPrice * BigInt.from(quantity);
            final isEnough = balance >= totalPrice;

            return AlertDialog(
              backgroundColor: const Color(0xFFF9F5E3),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('购买「${herb.name}」'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => startHold(() {
                          if (quantity > 1) setState(() => quantity--);
                        }),
                        onTapUp: (_) => stopHold(),
                        onTapCancel: stopHold,
                        child: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$quantity', style: const TextStyle(fontSize: 16)),
                      ),
                      GestureDetector(
                        onTapDown: (_) => startHold(() {
                          setState(() => quantity++);
                        }),
                        onTapUp: (_) => stopHold(),
                        onTapCancel: stopHold,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '总价：${formatAnyNumber(totalPrice)} ${lingShiNames[type]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnough ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isEnough ? () => Navigator.pop(context, quantity) : null,
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    ).then((confirmedQty) async {
      if (confirmedQty == null || confirmedQty <= 0) return;

      final totalCost = unitPrice * BigInt.from(confirmedQty);
      await ResourcesStorage.subtract(field, totalCost);
      await HerbMaterialService.add(herb.name, confirmedQty);

      ToastTip.show(context, '成功购买「${herb.name}」 ×$confirmedQty');
      await _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (owned == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      width: 360,
      height: 480,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('丹药材料商店', style: TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (int level = 1; level <= 21; level++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '$level 阶',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: herbs
                            .where((h) => h.level == level)
                            .map((herb) {
                          final count = owned?[herb.name] ?? 0;
                          return GestureDetector(
                            onTap: () => _buy(herb),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 2),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    herb.image,
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 20),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    herb.name,
                                    style: const TextStyle(fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '${formatAnyNumber(herb.priceAmount)} ${lingShiNames[herb.priceType]}',
                                    style: const TextStyle(fontSize: 8),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '拥有：$count',
                                    style: const TextStyle(fontSize: 8, color: Colors.grey),
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
          ],
        ),
      ),
    );
  }
}
