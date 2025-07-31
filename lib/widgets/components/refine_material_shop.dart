import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_material_service.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import '../common/toast_tip.dart';
import '../../utils/number_format.dart';

class RefineMaterialShop extends StatelessWidget {
  const RefineMaterialShop({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMaterialShopDialog(context),
      child: Image.asset(
        'assets/images/lianqi_shop.png',
        width: 128,
        height: 128,
      ),
    );
  }

  void _showMaterialShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: const _RefineMaterialDialogContent(),
      ),
    );
  }
}

class _RefineMaterialDialogContent extends StatefulWidget {
  const _RefineMaterialDialogContent({super.key});

  @override
  State<_RefineMaterialDialogContent> createState() =>
      _RefineMaterialDialogContentState();
}

class _RefineMaterialDialogContentState
    extends State<_RefineMaterialDialogContent> {
  late List<RefineMaterial> materials;
  late Resources res;
  Map<String, int> ownedCounts = {};

  @override
  void initState() {
    super.initState();
    materials = RefineMaterialService.generateAllMaterials();
    _loadData();
  }

  Future<void> _loadData() async {
    res = await ResourcesStorage.load();

    final Map<String, int> counts = {};
    for (final mat in materials) {
      final count = await RefineMaterialService.getCount(mat.name);
      counts[mat.name] = count;
    }

    setState(() {
      ownedCounts = counts;
    });
  }

  Future<void> _buy(RefineMaterial mat) async {
    final type = mat.priceType;
    final unitPrice = BigInt.from(mat.priceAmount);
    final field = lingShiFieldMap[type]!;
    final balance = ResourcesStorage.getStoneAmount(res, type);

    int quantity = 1;
    Timer? _holdTimer;

    void _startHolding(VoidCallback callback) {
      callback(); // 立刻执行一次
      _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => callback());
    }

    void _stopHolding() {
      _holdTimer?.cancel();
      _holdTimer = null;
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
                  Text('购买「${mat.name}」'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _startHolding(() {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        }),
                        onTapUp: (_) => _stopHolding(),
                        onTapCancel: _stopHolding,
                        child: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$quantity', style: const TextStyle(fontSize: 16)),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startHolding(() {
                          setState(() => quantity++);
                        }),
                        onTapUp: (_) => _stopHolding(),
                        onTapCancel: _stopHolding,
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
      await RefineMaterialService.add(mat.name, confirmedQty);

      ToastTip.show(context, '成功购买「${mat.name}」 ×$confirmedQty');
      await _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 720,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '炼器材料商店',
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
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
                    Center(
                      child: Wrap(
                        spacing: 4, // 每个材料横向间距
                        runSpacing: 6, // 多行时的纵向间距（如果需要换行）
                        alignment: WrapAlignment.center, // ✅ 居中
                        children: materials
                            .where((m) => m.level == level)
                            .map((mat) {
                          final count = ownedCounts[mat.name] ?? 0;
                          return GestureDetector(
                            onTap: () => _buy(mat),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    mat.image,
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported, size: 20),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mat.name,
                                    style: const TextStyle(fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '${formatAnyNumber(mat.priceAmount)} ${lingShiNames[mat.priceType]}',
                                    style: const TextStyle(fontSize: 8),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '拥有：$count',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey,
                                    ),
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
