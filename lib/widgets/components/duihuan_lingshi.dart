import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

import '../../utils/number_format.dart';
import '../common/toast_tip.dart';

class DuihuanLingshi extends StatefulWidget {
  const DuihuanLingshi({super.key});

  @override
  State<DuihuanLingshi> createState() => _DuihuanLingshiState();
}

class _DuihuanLingshiState extends State<DuihuanLingshi> {
  int inputAmount = 0;  // 用户输入的兑换数量
  late Resources res;
  LingShiType selectedLingShiType = LingShiType.middle; // 默认选中中品灵石

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  // 加载资源数据
  Future<void> _loadResources() async {
    res = await ResourcesStorage.load();
    setState(() {});
  }

  // 更新输入数量
  void _updateInputAmount(String value) {
    final int newAmount = int.tryParse(value) ?? 0;
    setState(() {
      inputAmount = newAmount;
    });
  }

  void _showDuihuanDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '请输入要兑换的灵石数量',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildLingShiSelection(),
              const SizedBox(height: 16),
              if (selectedLingShiType != null) _buildInputField(),
              const SizedBox(height: 16),
              _buildBalanceDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLingShiSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 让元素平分一行
      children: LingShiType.values.map((type) {
        return Row(
          children: [
            Checkbox(
              value: selectedLingShiType == type,
              onChanged: (bool? value) {
                setState(() {
                  selectedLingShiType = value == true ? type : selectedLingShiType;
                });
              },
            ),
            Text(
              lingShiNames[type] ?? '',
              style: const TextStyle(fontSize: 12), // 字号缩小
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInputField() {
    final BigInt cost = lingShiRates[selectedLingShiType]!; // 根据选中的类型来选择兑换的灵石
    final BigInt currentLow = getStoneValue(res, LingShiType.lower); // 获取下品灵石数量

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          onChanged: _updateInputAmount,
          decoration: InputDecoration(
            labelText: '输入兑换数量',
            hintText: '最大兑换 ${currentLow ~/ cost}', // 使用整型进行比较
            border: OutlineInputBorder(),
            errorText: inputAmount > (currentLow ~/ cost).toInt() ? '数量超出可兑换范围' : null, // 将BigInt转换为int进行比较
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '需要下品灵石：${(cost * BigInt.from(inputAmount)).toString()}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            if (inputAmount <= 0) {
              ToastTip.show(context, '❌ 请输入兑换数量');
              return;
            }

            if (currentLow >= cost * BigInt.from(inputAmount)) {
              await ResourcesStorage.subtract('spiritStoneLow', cost * BigInt.from(inputAmount)); // 扣除下品灵石
              await ResourcesStorage.add(
                'spiritStone${lingShiNames[selectedLingShiType]}',
                BigInt.from(inputAmount),
              ); // 增加相应灵石（可以根据类型修改）
              ToastTip.show(context, '✅ 成功兑换 $inputAmount ${lingShiNames[selectedLingShiType]}');
              Navigator.of(context).pop();
            } else {
              ToastTip.show(context, '❌ 下品灵石不足，兑换失败');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown.shade100,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text('兑换'),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStoneRow(LingShiType.lower, res.spiritStoneLow, 'assets/images/spirit_stone_low.png'),
        _buildStoneRow(LingShiType.middle, res.spiritStoneMid ?? BigInt.zero, 'assets/images/spirit_stone_mid.png'),
        _buildStoneRow(LingShiType.upper, res.spiritStoneHigh ?? BigInt.zero, 'assets/images/spirit_stone_high.png'),
        _buildStoneRow(LingShiType.supreme, res.spiritStoneSupreme ?? BigInt.zero, 'assets/images/spirit_stone_supreme.png'),
      ],
    );
  }

  Widget _buildStoneRow(LingShiType type, BigInt count, String imagePath) {
    return Row(
      children: [
        Image.asset(
          imagePath,  // 使用 Image.asset 来读取图片文件
          width: 24,  // 控制图片大小
          height: 24, // 控制图片高度
        ),
        const SizedBox(width: 8),
        Text(
          '${lingShiNames[type]}：${formatAnyNumber(count)}',  // 使用 formatAnyNumber 格式化数量
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }

  /// 🧠 从 Resources 中获取对应类型的灵石值
  BigInt getStoneValue(Resources res, LingShiType type) {
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
