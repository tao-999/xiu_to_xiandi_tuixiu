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
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9F5E3),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ZhaomuPage()),
              );
              onRecruitSuccess();
            },
            child: const Text(
              "前往招募",
              style: TextStyle(fontSize: 16, fontFamily: 'ZcoolCangEr'),
            ),
          ),
        ],
      ),
    );
  }
}
