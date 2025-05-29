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
    final unlockedStage = ((level.totalLayer - 1) ~/ 9 + 1).clamp(1, 9);

    print("😮‍💨 level=$level ------- unlockedStage=$unlockedStage");

    setState(() {
      maxStage = unlockedStage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      title: const Text("选择挂机地图"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: ListView.builder(
          itemCount: 9,
          itemBuilder: (context, index) {
            final stage = index + 1;
            final isSelected = stage == widget.currentStage;
            final isDisabled = stage > maxStage;
            final name = ['一','二','三','四','五','六','七','八','九'][index];
            final efficiency = pow(2, stage - 1).toInt();

            return ListTile(
              enabled: !isDisabled,
              title: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: isDisabled ? Colors.grey : Colors.black,
                  ),
                  children: [
                    TextSpan(text: '$name阶地图'),
                    TextSpan(
                      text: '（挂机效率 ×$efficiency）',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDisabled ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: isDisabled
                  ? null
                  : () {
                Navigator.of(context).pop();
                widget.onSelected(stage);
              },
            );
          },
        ),
      ),
    );
  }
}
