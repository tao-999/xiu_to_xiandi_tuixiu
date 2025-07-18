import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

class CultivationProgressBar extends StatelessWidget {
  final BigInt current;
  final BigInt max;
  final String realm;
  final int rank;

  const CultivationProgressBar({
    super.key,
    required this.current,
    required this.max,
    required this.realm,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = current == BigInt.zero || max == BigInt.zero
        ? 0.0
        : current.toDouble() / max.toDouble();

    final bool isMaxed = max == BigInt.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rank == 0 ? realm : "$realm$rank层",
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              if (isMaxed)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    '（已满级）',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          if (!isMaxed) ...[
            const SizedBox(height: 4),
            Text(
              "修为：${formatAnyNumber(current)} / ${formatAnyNumber(max)}",
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              minHeight: 10,
            ),
          ],
        ],
      ),
    );
  }
}
