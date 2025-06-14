import 'package:flutter/material.dart';

class WuxingAllocationPanel extends StatelessWidget {
  final int gold;
  final int wood;
  final int water;
  final int fire;
  final int earth;
  final int maxTotal;
  final void Function(String element, int value) onValueChanged;

  const WuxingAllocationPanel({
    super.key,
    required this.gold,
    required this.wood,
    required this.water,
    required this.fire,
    required this.earth,
    this.maxTotal = 30,
    required this.onValueChanged,
  });

  int get currentTotal => gold + wood + water + fire + earth;

  @override
  Widget build(BuildContext context) {
    final elements = {
      '金': gold,
      '木': wood,
      '水': water,
      '火': fire,
      '土': earth,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'ZcoolCangEr'),
            children: [
              const TextSpan(
                text: '五行天赋分配',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              TextSpan(
                text: '（上限30，剩余点数：${maxTotal - currentTotal}）',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 6,
          children: elements.entries.map((entry) {
            final label = entry.key;
            final value = entry.value;
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$label：$value",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14, // ✅ 自己调节字号大小
                      fontFamily: 'ZcoolCangEr', // 可选：统一骚字体
                    ),
                  ),
                  Slider(
                    min: 0,
                    max: 15,
                    divisions: 15,
                    label: value.toString(),
                    value: value.toDouble(),
                    activeColor: Colors.black.withOpacity(0.5),
                    inactiveColor: Colors.black,
                    onChanged: (val) {
                      if (currentTotal - value + val.toInt() <= maxTotal) {
                        onValueChanged(label, val.toInt());
                      }
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
