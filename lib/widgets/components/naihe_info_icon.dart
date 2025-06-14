import 'package:flutter/material.dart';

class NaiheInfoIcon extends StatelessWidget {
  final String title;
  final String description;

  const NaiheInfoIcon({
    super.key,
    this.title = '奈何桥规则',
    this.description = '''
奈何桥，是生与死的分界线。

修士重启人生，需饮下孟婆汤，方可抹除前缘。

喝了此汤，忘却前尘，重新投胎修行。

否则，记忆与执念将成为下一世的心魔，永难登仙。

你准备好轮回了吗？
''',
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // ✅ 重点：直角无圆弧
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'ZcoolCangEr',
            fontSize: 18,
          ),
        ),
        content: Text(
          description,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'ZcoolCangEr',
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.white),
      onPressed: () => _showInfoDialog(context),
      tooltip: '查看奈何桥设定',
    );
  }
}
