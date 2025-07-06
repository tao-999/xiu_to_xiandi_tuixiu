import 'package:flutter/material.dart';

class LianqiHeader extends StatelessWidget {
  final int level;

  const LianqiHeader({super.key, required this.level});

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
          onPressed: () => _showDescriptionDialog(context),
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
        insetPadding: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  '⚒️ 炼器房',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'ZcoolCangEr',
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '炼炉赤焰照寒霜，\n千锤百炼铸锋芒。\n灵材融尽三千界，\n一器横空镇八荒。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4E342E),
                    fontFamily: 'ZcoolCangEr',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '修者可淬炼神兵，需消耗稀有图纸与灵材。\n宗门等级越高，炼制的神器越强。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
