import 'package:flutter/material.dart';

class LianqiHeader extends StatelessWidget {
  final int level;

  const LianqiHeader({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '⚒️ 炼器房',
          style: TextStyle(
            fontSize: 20,
            color: Colors.deepOrangeAccent,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$level 级',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          onPressed: () {
            _showDescriptionDialog(context);
          },
        ),
      ],
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '炼器房说明',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'ZcoolCangEr',
                  color: Color(0xFF4E342E),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '在炼器房中，弟子们可炼制飞剑、战斧、护甲等法器。\n\n'
                    '炼器产出将根据等级与驻守弟子的能力决定。\n\n'
                    '炼器等级越高，成功率和产出品阶越高。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF4E342E),
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
