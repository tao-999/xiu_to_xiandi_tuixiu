import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';

class CultivationBoostDialog extends StatefulWidget {
  final VoidCallback? onUpdated;

  const CultivationBoostDialog({super.key, this.onUpdated});

  static Widget buildButton({
    required BuildContext context,
    VoidCallback? onUpdated,
  }) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => CultivationBoostDialog(onUpdated: onUpdated),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          "升修为",
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'ZcoolCangEr',
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  State<CultivationBoostDialog> createState() => _CultivationBoostDialogState();
}

class _CultivationBoostDialogState extends State<CultivationBoostDialog> {
  String lowStr = '';
  String midStr = '';
  String highStr = '';
  String supremeStr = '';

  BigInt lowOwned = BigInt.zero;
  BigInt midOwned = BigInt.zero;
  BigInt highOwned = BigInt.zero;
  BigInt supremeOwned = BigInt.zero;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadResourceValues();
  }

  Future<void> _loadResourceValues() async {
    lowOwned = await ResourcesStorage.getValue('spiritStoneLow');
    midOwned = await ResourcesStorage.getValue('spiritStoneMid');
    highOwned = await ResourcesStorage.getValue('spiritStoneHigh');
    supremeOwned = await ResourcesStorage.getValue('spiritStoneSupreme');

    if (mounted) setState(() => loading = false);
  }

  BigInt _parse(String s) => BigInt.tryParse(s) ?? BigInt.zero;

  BigInt get estimatedExp => PlayerStorage.calculateAddedExp(
    low: _parse(lowStr),
    mid: _parse(midStr),
    high: _parse(highStr),
    supreme: _parse(supremeStr),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final estimatedExpFormatted = formatAnyNumber(estimatedExp.toDouble());

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StoneInputRow(
            label: '下品灵石',
            owned: lowOwned.toString(),
            value: lowStr,
            onChanged: (v) => setState(() => lowStr = v),
          ),
          StoneInputRow(
            label: '中品灵石',
            owned: midOwned.toString(),
            value: midStr,
            onChanged: (v) => setState(() => midStr = v),
          ),
          StoneInputRow(
            label: '上品灵石',
            owned: highOwned.toString(),
            value: highStr,
            onChanged: (v) => setState(() => highStr = v),
          ),
          StoneInputRow(
            label: '极品灵石',
            owned: supremeOwned.toString(),
            value: supremeStr,
            onChanged: (v) => setState(() => supremeStr = v),
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
        InkWell(
          onTap: () async {
            final lowBI = _parse(lowStr);
            final midBI = _parse(midStr);
            final highBI = _parse(highStr);
            final supremeBI = _parse(supremeStr);
            final totalBI = lowBI + midBI + highBI + supremeBI;

            if (totalBI == BigInt.zero) {
              ToastTip.show(context, '灵石少得我都替你脸红');
              return;
            }
            if (lowBI > lowOwned ||
                midBI > midOwned ||
                highBI > highOwned ||
                supremeBI > supremeOwned) {
              ToastTip.show(context, '灵石不足，无法提升修为');
              return;
            }

            await PlayerStorage.addCultivationByStones(
              low: lowBI,
              mid: midBI,
              high: highBI,
              supreme: supremeBI,
              onUpdate: () {
                if (mounted) Navigator.of(context).pop();
                widget.onUpdated?.call();
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upgrade, color: Color(0xFFD28C41)),
                const SizedBox(width: 6),
                const Text(
                  '提升修为',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD28C41),
                    fontFamily: 'ZcoolCangEr',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StoneInputRow extends StatefulWidget {
  final String label;
  final String owned;
  final String value;
  final ValueChanged<String> onChanged;

  const StoneInputRow({
    required this.label,
    required this.owned,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  State<StoneInputRow> createState() => _StoneInputRowState();
}

class _StoneInputRowState extends State<StoneInputRow> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant StoneInputRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      controller.text = widget.value;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownedBI = BigInt.tryParse(widget.owned) ?? BigInt.zero;
    final enteredBI = BigInt.tryParse(controller.text) ?? BigInt.zero;
    final remainBI = ownedBI - enteredBI < BigInt.zero ? BigInt.zero : ownedBI - enteredBI;
    final remainStr = formatAnyNumber(remainBI.toDouble());

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
                  '剩余：$remainStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: enteredBI > ownedBI ? Colors.red : Colors.grey,
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
                    widget.onChanged(v);
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
                      controller.text = widget.owned;
                      controller.selection = TextSelection.collapsed(offset: controller.text.length);
                      widget.onChanged(widget.owned);
                      setState(() {});
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
