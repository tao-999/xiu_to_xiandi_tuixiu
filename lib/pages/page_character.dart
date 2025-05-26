import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/cultivator_info_card.dart';

class CharacterPage extends StatelessWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Character player = Character(
      id: '001',
      name: '雨落尘',
      gender: 'male',
      realm: '炼气三层',
      career: '散修',
      level: 11,
      exp: 40,
      expMax: 150,
      hp: 300,
      atk: 130,
      def: 3,
      atkSpeed: 1.0,
      critRate: 0.05,
      critDamage: 0.2,
      dodgeRate: 0.0,
      lifeSteal: 0.0,
      breakArmorRate: 0.0,
      luckRate: 0.0,
      comboRate: 0.0,
      evilAura: 0.0,
      weakAura: 0.0,
      corrosionAura: 0.0,
      elements: {'金': 9, '木': 6, '水': 5, '火': 4, '土': 6},
      technique: '赤焰心经',
    );

    final imagePath = player.gender == 'female'
        ? 'assets/images/icon_dazuo_female_256.png'
        : 'assets/images/icon_dazuo_male_256.png';

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_xiuxian_mountain.png',
              fit: BoxFit.cover,
            ),
          ),

          // 打坐动画 + 信息卡片
          Align(
            alignment: const Alignment(0, 0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeditationWidget(
                  imagePath: imagePath,
                  ready: true,
                  offset: const AlwaysStoppedAnimation(Offset.zero),
                  opacity: const AlwaysStoppedAnimation(1.0),
                  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                ),
                CultivatorInfoCard(profile: player), // ✅ 真实实例传参
              ],
            ),
          ),

          // 左下角返回按钮
          Positioned(
            left: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_back, size: 20, color: Colors.white),
                    SizedBox(width: 6),
                    Text('返回', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
