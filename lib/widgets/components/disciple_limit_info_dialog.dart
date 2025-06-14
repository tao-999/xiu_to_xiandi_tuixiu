import 'package:flutter/material.dart';

class DiscipleLimitInfoDialog extends StatelessWidget {
  const DiscipleLimitInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      content: const Text(
        "宗门等级越高，容纳的弟子就越多。\n\n"
            "等级对照表：\n"
            "1级：5人\n"
            "2级：10人\n"
            "3级：15人\n"
            "4级：20人\n"
            "5级：25人\n"
            "6级：30人\n"
            "7级：35人\n"
            "8级：40人\n"
            "9级：45人\n"
            "......",
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'ZcoolCangEr',
        ),
      ),
    );
  }
}
