// 📦 文件：stone_counter.dart
import 'package:flutter/material.dart';

class StoneCounter extends StatelessWidget {
  final String playerName;
  final String realm;
  final String label;
  final int count;
  final Color color;

  const StoneCounter({
    super.key,
    required this.playerName,
    required this.realm,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // ❌ 移除背景装饰，保持纯净
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：称号 + 境界
          Text(
            '$playerName · $realm',
            style: TextStyle(
              color: color, // ✅ 同棋子颜色
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          // 第二行：棋子颜色 + 数量
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
              Text(
                '【$label】$count',
                style: TextStyle(
                  color: color, // ✅ 字体颜色统一
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
