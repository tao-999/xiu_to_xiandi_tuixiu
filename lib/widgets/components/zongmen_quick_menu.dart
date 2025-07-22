import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciples.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_danfang.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_lianqi.dart';
import '../../pages/page_zongmen_diplomacy.dart';
import '../../pages/page_zongmen_roles.dart';

class ZongmenQuickMenu extends StatelessWidget {
  const ZongmenQuickMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ["弟子闺房", "dizi", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscipleListPage()))],
      ["炼丹房", "liandan", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanfangPage()))],
      ["炼器房", "lianqi", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LianqiPage()))],
      ["宗门外交", "waijiao", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZongmenDiplomacyPage()))],
      ["宗门广场", "zhiwei", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZongmenRolesPage()))],
    ];

    const radius = 120.0; // 圆形半径
    const buttonWidth = 60.0;
    const buttonHeight = 76.0;

    final angles = [
      -pi / 2,        // 顶部
      -pi / 10,       // 右上
      3 * pi / 10,    // 右下
      7 * pi / 10,    // 左下
      11 * pi / 10,   // 左上
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        return Stack(
          children: List.generate(5, (i) {
            final angle = angles[i];
            final dx = centerX + radius * cos(angle);
            final dy = centerY + radius * sin(angle);
            return Positioned(
              left: dx - buttonWidth / 2,
              top: dy - buttonHeight / 2,
              child: _quickButton(
                label: actions[i][0] as String,
                iconName: actions[i][1] as String,
                onTap: actions[i][2] as VoidCallback,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _quickButton({
    required String label,
    required String iconName,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/zongmen_$iconName.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'ZcoolCangEr',
            ),
          ),
        ],
      ),
    );
  }
}
