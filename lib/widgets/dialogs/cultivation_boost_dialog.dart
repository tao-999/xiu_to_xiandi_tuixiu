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
  int low = 0;
  int mid = 0;
  int high = 0;
  int supreme = 0;

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

  int get estimatedExp => PlayerStorage.calculateAddedExp(
    low: low,
    mid: mid,
    high: high,
    supreme: supreme,
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    final res = player.resources;

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      title: const Text('消耗灵石提升修为', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StoneInputRow(label: '下品灵石', owned: res.spiritStoneLow, onChanged: (v) => setState(() => low = v)),
          StoneInputRow(label: '中品灵石', owned: res.spiritStoneMid, onChanged: (v) => setState(() => mid = v)),
          StoneInputRow(label: '上品灵石', owned: res.spiritStoneHigh, onChanged: (v) => setState(() => high = v)),
          StoneInputRow(label: '极品灵石', owned: res.spiritStoneSupreme, onChanged: (v) => setState(() => supreme = v)),
          const SizedBox(height: 12),
          Text(
            '预估将提升修为：${formatLargeNumber(estimatedExp)}',
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
            if (total == 0) {
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class StoneInputRow extends StatefulWidget {
  final String label;
  final int owned;
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
                  formatLargeNumber(remain),
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
                      _updateValue(widget.owned);
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
