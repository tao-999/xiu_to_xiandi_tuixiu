import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/format_large_number.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

class CultivationBoostDialog extends StatefulWidget {
  final VoidCallback? onUpdated;

  const CultivationBoostDialog({super.key, this.onUpdated});

  /// ✅ 封装一个按钮，一行调用，自动弹窗+刷新
  static Widget buildButton({required BuildContext context, VoidCallback? onUpdated}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(40, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => CultivationBoostDialog(onUpdated: onUpdated),
        );
      },
      child: const Text("升修为", style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  @override
  State<CultivationBoostDialog> createState() => _CultivationBoostDialogState();
}

class _CultivationBoostDialogState extends State<CultivationBoostDialog> {
  // 改为 BigInt 类型，避免后续的转换
  BigInt low = BigInt.zero;
  BigInt mid = BigInt.zero;
  BigInt high = BigInt.zero;
  BigInt supreme = BigInt.zero;

  late Character player;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    player = (await PlayerStorage.getPlayer())!;
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // 直接返回 BigInt 类型，避免转换
  BigInt get estimatedExp => PlayerStorage.calculateAddedExp(
    low: low,       // 使用 BigInt 类型
    mid: mid,       // 使用 BigInt 类型
    high: high,     // 使用 BigInt 类型
    supreme: supreme, // 使用 BigInt 类型
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    final res = player.resources;

    // 直接传递 BigInt 类型，不需要转换为 double
    final estimatedExpFormatted = formatLargeNumber(estimatedExp.toDouble());

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      title: const Text('消耗灵石提升修为'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StoneInputRow(
            label: '下品灵石',
            owned: res.spiritStoneLow.toDouble(), // Convert BigInt to double for display
            onChanged: (v) => setState(() => low = BigInt.from(v)),
          ),
          StoneInputRow(
            label: '中品灵石',
            owned: res.spiritStoneMid.toDouble(), // Convert BigInt to double for display
            onChanged: (v) => setState(() => mid = BigInt.from(v)),
          ),
          StoneInputRow(
            label: '上品灵石',
            owned: res.spiritStoneHigh.toDouble(), // Convert BigInt to double for display
            onChanged: (v) => setState(() => high = BigInt.from(v)),
          ),
          StoneInputRow(
            label: '极品灵石',
            owned: res.spiritStoneSupreme.toDouble(), // Convert BigInt to double for display
            onChanged: (v) => setState(() => supreme = BigInt.from(v)),
          ),
          const SizedBox(height: 12),
          Text(
            '预估将提升修为：$estimatedExpFormatted',
            style: const TextStyle(fontSize: 14, color: Colors.brown),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD28C41),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () async {
            final res = player.resources;

            final total = low + mid + high + supreme;
            if (total == BigInt.zero) {
              ToastTip.show(context, '灵石少得我都替你脸红');
              return;
            }

            if (low > res.spiritStoneLow ||
                mid > res.spiritStoneMid ||
                high > res.spiritStoneHigh ||
                supreme > res.spiritStoneSupreme) {
              ToastTip.show(context, '灵石不足，无法提升修为');
              return;
            }

            await PlayerStorage.addCultivationByStones(
              low: low,
              mid: mid,
              high: high,
              supreme: supreme,
              onUpdate: () {
                if (mounted) Navigator.of(context).pop();
                widget.onUpdated?.call();
              },
            );
          },
          child: const Text(
            '提升修为',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class StoneInputRow extends StatefulWidget {
  final String label;
  final double owned; // Convert to double for display purposes
  final Function(int) onChanged;

  const StoneInputRow({
    required this.label,
    required this.owned,
    required this.onChanged,
    super.key,
  });

  @override
  State<StoneInputRow> createState() => _StoneInputRowState();
}

class _StoneInputRowState extends State<StoneInputRow> {
  final TextEditingController controller = TextEditingController();
  int value = 0;

  void _updateValue(int newValue) {
    value = newValue;
    controller.text = value.toString();
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    widget.onChanged(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remain = (widget.owned - value).clamp(0, widget.owned);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  formatLargeNumber(remain), // Remain is now a double
                  style: TextStyle(
                    fontSize: 12,
                    color: (value > widget.owned) ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v) ?? 0;
                    value = parsed;
                    widget.onChanged(value);
                    setState(() {});
                  },
                ),
                Positioned(
                  right: 4,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(36, 32),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      _updateValue(widget.owned.toInt()); // Convert to int before updating
                    },
                    child: const Text("最大", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}