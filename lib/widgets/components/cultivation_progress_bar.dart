import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import '../dialogs/cultivation_boost_dialog.dart';

class CultivationProgressBar extends StatelessWidget {
  final BigInt current;
  final BigInt max;
  final String realm;
  final int rank;

  /// ✅ 新增：外部刷新回调
  final VoidCallback? onUpdated;

  const CultivationProgressBar({
    super.key,
    required this.current,
    required this.max,
    required this.realm,
    required this.rank,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = current == BigInt.zero || max == BigInt.zero
        ? 0.0
        : current.toDouble() / max.toDouble();

    final bool isMaxed = max == BigInt.zero;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              rank == 0 ? realm : "$realm$rank层",
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
            if (!isMaxed)
              CultivationBoostDialog.buildButton(
                context: context,
                onUpdated: () {
                  onUpdated?.call(); // ✅ 关键点：触发外部刷新
                },
              ),
            if (isMaxed)
              const Padding(
                padding: EdgeInsets.only(left: 4),
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
          Text(
            "${formatAnyNumber(current)} / ${formatAnyNumber(max)}",
            style: const TextStyle(color: Colors.black45, fontSize: 8),
          ),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            minHeight: 6,
          ),
        ],
      ],
    );
  }
}
