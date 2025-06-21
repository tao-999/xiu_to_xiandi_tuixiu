// 📁 lib/widgets/dialogs/chess_stone_select_dialog.dart
import 'package:flutter/material.dart';

class ChessStoneSelectDialog extends StatelessWidget {
  final void Function(int selectedStone) onStoneSelected;

  const ChessStoneSelectDialog({
    super.key,
    required this.onStoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择你的棋子颜色',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '此选择将永久保存，无法更改。\n你将永远是先手执棋。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStoneOption(context, 1, Colors.black87, Colors.black, '执黑'),
                _buildStoneOption(context, 2, Colors.white, Colors.grey, '执白'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoneOption(BuildContext context, int value, Color c1, Color c2, String label) {
    return GestureDetector(
      onTap: () => onStoneSelected(value),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 0.8,
                colors: [c1, c2],
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
