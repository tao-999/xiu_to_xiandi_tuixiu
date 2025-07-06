import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/pill_blueprint_service.dart';

class DanfangHeader extends StatelessWidget {
  final int level;

  const DanfangHeader({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '🔥 炼丹房',
          style: TextStyle(
            fontSize: 20,
            color: Colors.orangeAccent,
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  '🔥 炼丹房',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'ZcoolCangEr',
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '炼炉丹香动九天，\n赤火青烟绕指旋。\n一粒入喉生妙法，\n千般造化在炉边。',
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
                  '修者可炼制灵丹妙药，助修行飞升。\n宗门等级越高，可炼丹方越多，药效越强。',
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
