import 'package:flutter/material.dart';

class ChessPoemDialog extends StatelessWidget {
  const ChessPoemDialog({super.key});

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F5E3),
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          content: const SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '仙灵棋阵 · 序',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '执子布灵枰，天地一局明。\n'
                      '气机藏胜负，玄奥动纵横。\n'
                      '丹心凝阵眼，灵识化飞星。\n'
                      '若问输赢处，谁解道中兵。',
                  style: TextStyle(fontSize: 14, height: 2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 16,
      child: IconButton(
        icon: const Icon(
          Icons.auto_stories,
          size: 20,
          color: Colors.white, // 💡 就是这里！改成你想要的颜色
        ),
        tooltip: '棋阵序诗',
        onPressed: () => _showDialog(context),
      ),
    );
  }
}
