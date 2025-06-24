import 'package:flutter/material.dart';

class HellLevelOverlay extends StatelessWidget {
  final int level;

  const HellLevelOverlay({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(top: 32, right: 16),
      child: Text(
        '幽冥 $level 层',
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 12,
        ),
      ),
    );
  }
}
