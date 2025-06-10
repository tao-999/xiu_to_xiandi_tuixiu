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
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: [
              const TextSpan(
                text: '五行天赋分配（上限30，剩余点数：',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: '${maxTotal - currentTotal}',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const TextSpan(
                text: '）',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: elements.entries.map((entry) {
            final label = entry.key;
            final value = entry.value;
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$label：$value", style: const TextStyle(color: Colors.black)),
                  Slider(
                    min: 0,
                    max: 15,
                    divisions: 15,
                    label: value.toString(),
                    value: value.toDouble(),
                    activeColor: Colors.teal,
                    inactiveColor: Colors.teal.shade100,
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
