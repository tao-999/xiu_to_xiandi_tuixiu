// 📄 lib/widgets/components/root_bottom_menu.dart
import 'package:flutter/material.dart';

class RootBottomMenu extends StatelessWidget {
  final String gender;
  final void Function(int index) onTap;

  const RootBottomMenu({
    super.key,
    required this.gender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['角色', '背包', '游历', '宗门', '招募'];
    final iconPaths = [
      gender == 'female'
          ? 'assets/images/icon_dazuo_female.png'
          : 'assets/images/icon_dazuo_male.png',
      'assets/images/icon_beibao.png',
      gender == 'female'
          ? 'assets/images/icon_youli_female.png'
          : 'assets/images/icon_youli_male.png',
      'assets/images/icon_zongmen.png',
      'assets/images/icon_zhaomu.png',
    ];

    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (index) {
          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(iconPaths[index], fit: BoxFit.cover),
                ),
                const SizedBox(height: 2),
                Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
