// 📂 lib/widgets/components/pill_consumer.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_storage_service.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

import '../../services/player_storage.dart';

class PillConsumer extends StatelessWidget {
  final VoidCallback? onConsumed;

  const PillConsumer({super.key, this.onConsumed});

  void _showPillDialog(BuildContext context) async {
    final pills = await PillStorageService.loadAllPills();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF8F1D4),
        insetPadding: const EdgeInsets.all(16), // ✅ 跟你给的代码保持一致
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // 没 tooltip 也保留结构一致性
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: pills.isEmpty
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    '你连颗丹药都没有，\n修炼靠脸吃饭吗？',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '赶紧去丹房炼几炉，不然靠什么打脸仇家？',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              )
                  : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: pills.map((pill) {
                  return GestureDetector(
                    onTap: () => _showQuantityDialog(context, pill),
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/${pill.iconPath}',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pill.name} × ${pill.count}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            '+${formatAnyNumber(pill.bonusAmount)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Pill pill) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          // 计算加成属性展示
          final totalBonus = pill.bonusAmount * quantity;
          final typeText = _getTypeText(pill.type);

          return AlertDialog(
            backgroundColor: const Color(0xFFF8F1D4),
            insetPadding: const EdgeInsets.all(16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            actionsPadding: const EdgeInsets.only(bottom: 8),
            title: Center( // ✅ 名字居中
              child: Text(
                '吞服 ${pill.name}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/${pill.iconPath}', width: 42, height: 42),
                const SizedBox(height: 4),
                Text(
                  '选择数量（最多 ${pill.count}）',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: quantity < pill.count
                          ? () => setState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => quantity = pill.count),
                      child: const Text(
                        '最大',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '本次加成：+$totalBonus $typeText',
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () async {
                  await PillStorageService.consumePill(pill, count: quantity);

                  // ✅ 计算属性加成
                  await PlayerStorage.applyPillBonus(
                    type: pill.type.name,               // 'hp' | 'atk' | 'def'
                    bonusPerPill: pill.bonusAmount,
                    count: quantity,
                  );

                  ToastTip.show(context, '吞服 ${pill.name} ×$quantity 成功！');
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  onConsumed?.call();
                },
                child: const Text(
                  '确认',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getTypeText(PillType type) {
    switch (type) {
      case PillType.attack:
        return '攻击';
      case PillType.defense:
        return '防御';
      case PillType.health:
        return '血气';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPillDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Text(
          '吞丹',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'ZcoolCangEr',
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
