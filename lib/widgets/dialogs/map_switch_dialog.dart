import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart'; // ✅ 使用用户已有类

class MapSwitchDialog extends StatelessWidget {
  final int currentStage;
  final double cultivationExp;
  final void Function(int stage) onSelected;

  const MapSwitchDialog({
    super.key,
    required this.currentStage,
    required this.cultivationExp,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final level = calculateCultivationLevel(cultivationExp);
    final realmIndex = realms.indexOf(level.realm);
    final maxStage = (realmIndex + 1).clamp(1, 9);

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
            final isSelected = stage == currentStage;
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
                onSelected(stage);
              },
            );
          },
        ),
      ),
    );
  }
}
