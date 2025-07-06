import 'package:flutter/material.dart';

class DiscipleListHeader extends StatelessWidget {
  final int count;
  final int maxCount;
  final String sortOption;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onInfoTap;

  const DiscipleListHeader({
    Key? key,
    required this.count,
    required this.maxCount,
    required this.sortOption,
    required this.onSortChanged,
    required this.onInfoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "弟子闺房",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onInfoTap,
          child: const Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: sortOption,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'ZcoolCangEr',
                  ),
                  dropdownColor: const Color(0xFF1D1A17),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'apt_desc', child: Text('资质:高→低')),
                    DropdownMenuItem(value: 'apt_asc', child: Text('资质:低→高')),
                    DropdownMenuItem(value: 'age_desc', child: Text('年龄:大→小')),
                    DropdownMenuItem(value: 'age_asc', child: Text('年龄:小→大')),
                    DropdownMenuItem(value: 'atk_desc', child: Text('战力:高→低')),
                    DropdownMenuItem(value: 'atk_asc', child: Text('战力:低→高')),
                    DropdownMenuItem(value: 'favor_desc', child: Text('好感:高→低')),
                    DropdownMenuItem(value: 'favor_asc', child: Text('好感:低→高')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      onSortChanged(v);
                    }
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  '$count / $maxCount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
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
