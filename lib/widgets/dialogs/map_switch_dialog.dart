import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class MapSwitchDialog extends StatefulWidget {
  final int currentStage;
  final void Function(int stage) onSelected;

  const MapSwitchDialog({
    super.key,
    required this.currentStage,
    required this.onSelected,
  });

  @override
  State<MapSwitchDialog> createState() => _MapSwitchDialogState();
}

class _MapSwitchDialogState extends State<MapSwitchDialog> {
  int maxStage = 1;

  @override
  void initState() {
    super.initState();
    _loadMaxStage();
  }

  Future<void> _loadMaxStage() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final exp = player.cultivation;
    final level = calculateCultivationLevel(exp);

    // 计算已解锁的最大地图阶数
    final unlockedStage = ((level.totalLayer - 1) ~/ CultivationConfig.levelsPerRealm + 1)
        .clamp(1, CultivationConfig.realms.length);

    print('📍 当前层数: ${level.totalLayer}（${level.realm} 第${level.rank}重） → 解锁到第 $unlockedStage 阶地图');

    setState(() {
      maxStage = unlockedStage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final realmNames = CultivationConfig.realms;
    final itemCount = realmNames.length;

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      title: const Text(
        "选择挂机地图",
        style: TextStyle(fontSize: 16),
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final stage = index + 1;
            final isSelected = stage == widget.currentStage;
            final isDisabled = stage > maxStage;
            final name = realmNames[index];
            final efficiency = pow(2, stage - 1).toInt();

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                Navigator.of(context).pop();
                widget.onSelected(stage);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.withOpacity(0.1) : null,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: isDisabled ? Colors.grey : Colors.black,
                          ),
                          children: [
                            TextSpan(text: '$name地图'),
                            TextSpan(
                              text: '（挂机效率 ×$efficiency）',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDisabled
                                    ? Colors.grey.shade400
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
