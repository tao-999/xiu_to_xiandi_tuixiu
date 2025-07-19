import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/number_format.dart';
import '../common/toast_tip.dart';

class ImproveDiscipleRealmDialog extends StatefulWidget {
  final Disciple disciple;
  final VoidCallback? onRealmUpgraded;

  const ImproveDiscipleRealmDialog({
    super.key,
    required this.disciple,
    this.onRealmUpgraded,
  });

  @override
  State<ImproveDiscipleRealmDialog> createState() => _ImproveDiscipleRealmDialogState();
}

class _ImproveDiscipleRealmDialogState extends State<ImproveDiscipleRealmDialog> {
  final lowCtrl = TextEditingController();
  final midCtrl = TextEditingController();
  final highCtrl = TextEditingController();
  final supremeCtrl = TextEditingController();

  BigInt lowOwned = BigInt.zero;
  BigInt midOwned = BigInt.zero;
  BigInt highOwned = BigInt.zero;
  BigInt supremeOwned = BigInt.zero;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnedStones();

    // 核心骚点：监听所有输入框变化，自动setState刷新
    lowCtrl.addListener(_onInputChanged);
    midCtrl.addListener(_onInputChanged);
    highCtrl.addListener(_onInputChanged);
    supremeCtrl.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    lowCtrl.removeListener(_onInputChanged);
    midCtrl.removeListener(_onInputChanged);
    highCtrl.removeListener(_onInputChanged);
    supremeCtrl.removeListener(_onInputChanged);

    lowCtrl.dispose();
    midCtrl.dispose();
    highCtrl.dispose();
    supremeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOwnedStones() async {
    lowOwned = await ResourcesStorage.getValue('spiritStoneLow');
    midOwned = await ResourcesStorage.getValue('spiritStoneMid');
    highOwned = await ResourcesStorage.getValue('spiritStoneHigh');
    supremeOwned = await ResourcesStorage.getValue('spiritStoneSupreme');
    if (mounted) setState(() => loading = false);
  }

  BigInt _parse(String s) => BigInt.tryParse(s) ?? BigInt.zero;

  BigInt get estimatedTotal =>
      _parse(lowCtrl.text) * lingShiRates[LingShiType.lower]! +
          _parse(midCtrl.text) * lingShiRates[LingShiType.middle]! +
          _parse(highCtrl.text) * lingShiRates[LingShiType.upper]! +
          _parse(supremeCtrl.text) * lingShiRates[LingShiType.supreme]!;

  int get predictedLevel {
    final totalCultivation = BigInt.from(widget.disciple.cultivation) + estimatedTotal;
    return ZongmenDiscipleService.calculateUpgradedRealmLevel(
      currentLevel: 0, // 强制从0推算
      currentCultivation: BigInt.zero,
      addedCultivation: totalCultivation,
    );
  }

  BigInt get overflowCultivation {
    final total = BigInt.from(widget.disciple.cultivation) + estimatedTotal;
    final maxTotal = ZongmenDiscipleService.getMaxTotalCultivation();
    return total > maxTotal ? total - maxTotal : BigInt.zero;
  }

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

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 预估目标境界 ➤ 顶部显示
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '境界预估：${ZongmenDiscipleService.getRealmNameByLevel(predictedLevel)}',
              style: const TextStyle(fontSize: 14, color: Colors.brown),
            ),
          ),
          _StoneInputRow(
            label: '下品灵石',
            owned: lowOwned.toString(),
            controller: lowCtrl,
          ),
          _StoneInputRow(
            label: '中品灵石',
            owned: midOwned.toString(),
            controller: midCtrl,
          ),
          _StoneInputRow(
            label: '上品灵石',
            owned: highOwned.toString(),
            controller: highCtrl,
          ),
          _StoneInputRow(
            label: '极品灵石',
            owned: supremeOwned.toString(),
            controller: supremeCtrl,
          ),
          const SizedBox(height: 12),
          // 🌟 当前总修为（含本次输入）
          Text(
            '当前总修为值：${formatAnyNumber((BigInt.from(widget.disciple.cultivation) + estimatedTotal).toDouble())}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (overflowCultivation > BigInt.zero)
            Text(
              '⚠️ 超出修为：${formatAnyNumber(overflowCultivation.toDouble())}',
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        InkWell(
          onTap: _onSubmit,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upgrade, color: Color(0xFFD28C41)),
                SizedBox(width: 6),
                Text(
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

  Future<void> _onSubmit() async {
    final low = _parse(lowCtrl.text);
    final mid = _parse(midCtrl.text);
    final high = _parse(highCtrl.text);
    final supreme = _parse(supremeCtrl.text);
    final total = low + mid + high + supreme;

    if (total == BigInt.zero) {
      ToastTip.show(context, '你至少得给一点灵石吧😅');
      return;
    }

    if (low > lowOwned || mid > midOwned || high > highOwned || supreme > supremeOwned) {
      ToastTip.show(context, '灵石不够，你想骗系统？🤨');
      return;
    }

    final upgraded = await ZongmenDiscipleService.addCultivationToDisciple(
      widget.disciple,
      low: low,
      mid: mid,
      high: high,
      supreme: supreme,
    );

    final onUpgraded = upgraded && widget.onRealmUpgraded != null
        ? widget.onRealmUpgraded
        : null;

    if (mounted) {
      Navigator.of(context).pop();
      if (onUpgraded != null) {
        Future.microtask(widget.onRealmUpgraded!);
      }
    }
  }
}

/// 无状态输入框，controller全由外部传入，永远不炸
class _StoneInputRow extends StatelessWidget {
  final String label;
  final String owned;
  final TextEditingController controller;

  const _StoneInputRow({
    required this.label,
    required this.owned,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final ownedBI = BigInt.tryParse(owned) ?? BigInt.zero;
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
                Text(label, style: const TextStyle(fontSize: 14)),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      border: UnderlineInputBorder(),
                    ),
                    // 无 onChanged，外部监听即可，完全不受rebuild影响
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    controller.text = owned;
                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(36, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text("最大", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
