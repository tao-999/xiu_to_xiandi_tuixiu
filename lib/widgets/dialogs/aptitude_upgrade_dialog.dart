import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class AptitudeUpgradeDialog extends StatefulWidget {
  final Character player;

  const AptitudeUpgradeDialog({super.key, required this.player});

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

  @override
  void initState() {
    super.initState();
    tempElements = Map<String, int>.from(widget.player.elements);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.player.resources.fateRecruitCharm - tempUsed;
    final totalAptitude = tempElements.values.fold<int>(0, (sum, v) => sum + v);

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨ 资质：$totalAptitude',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('剩余资质券：$remaining',
              style: const TextStyle(color: Colors.orange, fontSize: 14)),
          const SizedBox(height: 8),
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
                    onPressed: remaining > 0
                        ? () {
                      setState(() {
                        tempElements[key] = currentValue + 1;
                        tempUsed++;
                      });
                    }
                        : null,
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
                await PlayerStorage.updateFields({
                  'resources': widget.player.resources.toMap(),
                  'elements': widget.player.elements,
                });
                if (context.mounted) Navigator.of(context).pop();
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
