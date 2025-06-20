import 'package:flutter/material.dart';

class AlchemyQuantitySelector extends StatelessWidget {
  final int maxCount;
  final int initial;
  final void Function(int) onChanged;

  const AlchemyQuantitySelector({
    super.key,
    required this.maxCount,
    required this.initial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ➖
        TextButton(
          onPressed: initial > 1 ? () => onChanged(initial - 1) : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: Colors.transparent,
          ),
          child: const Text(
            '－',
            style: TextStyle(fontSize: 24),
          ),
        ),

        const SizedBox(width: 12),

        // 中间数字
        Text(
          '$initial / $maxCount',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'RobotoMono',
          ),
        ),

        const SizedBox(width: 12),

        // ➕
        TextButton(
          onPressed: initial < maxCount ? () => onChanged(initial + 1) : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: Colors.transparent,
          ),
          child: const Text(
            '＋',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ],
    );
  }
}
