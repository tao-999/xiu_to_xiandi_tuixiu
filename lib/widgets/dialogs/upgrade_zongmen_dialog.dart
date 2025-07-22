import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

class UpgradeZongmenDialog extends StatelessWidget {
  final BigInt currentStones;
  final BigInt requiredStones;

  const UpgradeZongmenDialog({
    super.key,
    required this.currentStones,
    required this.requiredStones,
  });

  @override
  Widget build(BuildContext context) {
    final canUpgrade = currentStones >= requiredStones;

    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8DC), // 米黄色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // 直角边框
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔰 标题行
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
              SizedBox(width: 6),
              Text(
                '升级宗门',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 💰 灵石信息
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: '需要消耗',
                  style: TextStyle(fontSize: 12),
                ),
                TextSpan(
                  text: '${formatAnyNumber(requiredStones)} 下品灵石\n',
                  style: TextStyle(
                    fontSize: 10,
                    color: canUpgrade ? Colors.green : Colors.red,
                  ),
                ),
                TextSpan(
                  text: '（当前拥有：${formatAnyNumber(currentStones)}）',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // ⏫ 按钮区域
          GestureDetector(
            onTap: canUpgrade ? () => Navigator.of(context).pop(true) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upgrade, color: canUpgrade ? Colors.blue : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '升级宗门',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: canUpgrade ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
