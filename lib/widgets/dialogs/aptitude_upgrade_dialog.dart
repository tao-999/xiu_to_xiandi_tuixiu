import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

import '../constants/aptitude_table.dart';

class AptitudeUpgradeDialog extends StatefulWidget {
  final Character player;
  final VoidCallback? onUpdated;

  const AptitudeUpgradeDialog({
    super.key,
    required this.player,
    this.onUpdated,
  });

  static Widget buildButton({
    required BuildContext context,
    required Character player,
    VoidCallback? onUpdated,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(40, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (_) => AptitudeUpgradeDialog(
            player: player,
            onUpdated: onUpdated,
          ),
        );
      },
      child: const Text("升资质", style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  @override
  State<AptitudeUpgradeDialog> createState() => _AptitudeUpgradeDialogState();
}

class _AptitudeUpgradeDialogState extends State<AptitudeUpgradeDialog> {
  late Map<String, int> tempElements;
  int tempUsed = 0;

  final Map<String, String> elementLabels = {
    'gold': '金',
    'wood': '木',
    'water': '水',
    'fire': '火',
    'earth': '土',
  };

  int getMaxAptitudeLimit() {
    return aptitudeTable.last.minAptitude;
  }

  @override
  void initState() {
    super.initState();
    tempElements = Map<String, int>.from(widget.player.elements);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.player.resources.fateRecruitCharm - tempUsed;
    final totalAptitude = tempElements.values.fold<int>(0, (sum, v) => sum + v);
    final maxAptitudeLimit = getMaxAptitudeLimit();

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨ 资质：$totalAptitude / $maxAptitudeLimit', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text('剩余资质券：$remaining', style: const TextStyle(color: Colors.orange, fontSize: 14)),

          ...tempElements.keys.map((key) {
            final label = elementLabels[key] ?? key;
            final baseValue = widget.player.elements[key] ?? 0;
            final currentValue = tempElements[key] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text('$label：',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text('$currentValue', style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  if (currentValue > baseValue)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_circle, size: 20, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          tempElements[key] = currentValue - 1;
                          tempUsed--;
                        });
                      },
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle, size: 20, color: Colors.green),
                    onPressed: () {
                      final newTotal = totalAptitude + 1;

                      if (remaining <= 0) return;

                      if (newTotal > maxAptitudeLimit) {
                        ToastTip.show(context, '⚠️ 已达到资质上限，无法继续提升！');
                        return;
                      }

                      setState(() {
                        tempElements[key] = currentValue + 1;
                        tempUsed++;
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: tempUsed == 0
                  ? null
                  : () async {
                widget.player.resources.fateRecruitCharm -= tempUsed;
                widget.player.elements = tempElements;

                /// 🎯 新增：根据五行刷新基础属性
                PlayerStorage.calculateBaseAttributes(widget.player);

                await PlayerStorage.updateFields({
                  'resources': widget.player.resources.toMap(),
                  'elements': widget.player.elements,
                  'baseHp': widget.player.baseHp,
                  'baseAtk': widget.player.baseAtk,
                  'baseDef': widget.player.baseDef,
                });

                if (context.mounted) Navigator.of(context).pop();
                widget.onUpdated?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: tempUsed == 0 ? Colors.grey : Colors.orange[400],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '☯️ 确认提升',
                  style: TextStyle(
                    fontSize: 14,
                    color: tempUsed == 0 ? Colors.black38 : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
