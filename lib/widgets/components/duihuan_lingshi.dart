import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/lingshi_exchange_service.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

import '../../utils/number_format.dart';
import '../common/toast_tip.dart';

class DuihuanLingshi extends StatefulWidget {
  const DuihuanLingshi({super.key});

  @override
  State<DuihuanLingshi> createState() => _DuihuanLingshiState();
}

class _DuihuanLingshiState extends State<DuihuanLingshi> {
  int inputAmount = 0;
  late Resources res;
  LingShiType fromType = LingShiType.lower;
  LingShiType toType = LingShiType.middle;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    res = await ResourcesStorage.load();
    setState(() {});
  }

  // 显示兑换弹窗
  void _showDuihuanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFFF9F5E3),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('灵石兑换', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTypeSelector(true, setDialogState),
                      const Icon(Icons.arrow_forward, color: Colors.black54),
                      _buildTypeSelector(false, setDialogState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputSection(setDialogState),
                  const SizedBox(height: 12),
                  _buildBalanceDisplay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 选择灵石类型（From 或 To）
  Widget _buildTypeSelector(bool isFrom, void Function(void Function()) setState) {
    final LingShiType selected = isFrom ? fromType : toType;
    final LingShiType opposite = isFrom ? toType : fromType;

    return DropdownButton<LingShiType>(
      key: ValueKey(selected),
      value: selected,
        onChanged: (value) {
          if (value == null) return;

          // ✅ 干掉输入框的 focus
          FocusScope.of(context).unfocus();

          setState(() {
            if (isFrom) {
              fromType = value;
              if (fromType == toType) {
                toType = LingShiType.values.firstWhere((t) => t != fromType);
              }
            } else {
              toType = value;
              if (toType == fromType) {
                fromType = LingShiType.values.firstWhere((t) => t != toType);
              }
            }

            inputAmount = 0; // ✅ 清空输入框
          });
        },
        items: LingShiType.values.map((type) {
        final isDisabled = type == opposite;

        return DropdownMenuItem<LingShiType>(
          value: type,
          enabled: !isDisabled,
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: Row(
              children: [
                Image.asset(getLingShiImagePath(type), width: 16, height: 16),
                Text(
                  lingShiNames[type]!,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 输入框
  Widget _buildInputSection(void Function(void Function()) setDialogState) {
    final BigInt fromRate = lingShiRates[fromType]!;
    final BigInt toRate = lingShiRates[toType]!;
    final BigInt required = (toRate * BigInt.from(inputAmount) ~/ fromRate);
    final BigInt available = _getStoneValue(res, fromType);
    final int maxAmount = (available * fromRate ~/ toRate).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _inputController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (val) {
            final newAmount = int.tryParse(val) ?? 0;
            setDialogState(() {
              inputAmount = newAmount;
            });

            if (newAmount > maxAmount) {
              ToastTip.show(context, '⚠️ 超出最大可兑换数量（最多 $maxAmount）');
            }
          },
          decoration: const InputDecoration(
            labelText: '兑换数量',
            border: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '最多可兑换：${formatAnyNumber(maxAmount)} ${lingShiNames[toType]}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          '消耗：${formatAnyNumber(required)} ${lingShiNames[fromType]}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final int maxAllowed = (available * fromRate ~/ toRate).toInt();

            if (inputAmount <= 0) {
              ToastTip.show(context, '❌ 请输入兑换数量');
              return;
            }

            if (inputAmount > maxAllowed) {
              ToastTip.show(context, '❌ 超出最大可兑换数量');
              return;
            }

            if (required > available) {
              ToastTip.show(context, '❌ 灵石不足，兑换失败');
              return;
            }

            final success = await LingShiExchangeService.exchangeLingShi(
              fromType: fromType,
              toType: toType,
              inputAmount: inputAmount,
              res: res,
            );

            if (success) {
              ToastTip.show(context, '✅ 成功兑换 $inputAmount ${lingShiNames[toType]}');

              final updated = await ResourcesStorage.load();
              setDialogState(() {
                res = updated;
                inputAmount = 0;
                _inputController.clear();
                FocusScope.of(context).unfocus();
              });
            } else {
              ToastTip.show(context, '❌ 灵石不足，兑换失败');
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.swap_horiz, size: 24),
              Text(
                '立即兑换',
                style: TextStyle(fontSize: 15, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 显示可用的灵石数量
  Widget _buildBalanceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: LingShiType.values.map((type) {
        final BigInt count = _getStoneValue(res, type);
        return Row(
          children: [
            Image.asset(getLingShiImagePath(type), width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              '${lingShiNames[type]}：${formatAnyNumber(count)}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 获取当前灵石数量
  BigInt _getStoneValue(Resources res, LingShiType type) {
    switch (type) {
      case LingShiType.lower:
        return res.spiritStoneLow;
      case LingShiType.middle:
        return res.spiritStoneMid ?? BigInt.zero;
      case LingShiType.upper:
        return res.spiritStoneHigh ?? BigInt.zero;
      case LingShiType.supreme:
        return res.spiritStoneSupreme ?? BigInt.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDuihuanDialog(context),
      child: Image.asset(
        'assets/images/jishi_duihuanlingshi.png',
        width: 96,
        height: 96,
      ),
    );
  }
}
