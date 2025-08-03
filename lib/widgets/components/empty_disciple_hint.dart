import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_zhaomu.dart';

class EmptyDiscipleHint extends StatelessWidget {
  final VoidCallback onRecruitSuccess;

  const EmptyDiscipleHint({super.key, required this.onRecruitSuccess});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "一个人也没有，宗主你要孤独终老吗？",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
