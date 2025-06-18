import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/beibao_grid_view.dart';
import 'package:xiu_to_xiandi_tuixiu/data/beibao_resource_config.dart';

import '../services/weapons_storage.dart';

class BeibaoPage extends StatefulWidget {
  const BeibaoPage({super.key});

  @override
  State<BeibaoPage> createState() => _BeibaoPageState();
}

class _BeibaoPageState extends State<BeibaoPage> {
  List<BeibaoItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    List<BeibaoItem> newItems = [];

    // 🔹 1. 加载通用资源（灵石、招募券等）
    for (final config in beibaoResourceList) {
      final quantity = await ResourcesStorage.getValue(config.field);
      newItems.add(BeibaoItem(
        name: config.name,
        imagePath: config.imagePath,
        quantity: quantity,
        description: config.description,
      ));
    }

    // 🔹 2. 加载炼制武器
    final weapons = await WeaponsStorage.loadAllWeapons();

    // ✅ 打印详细武器信息
    print('🧱 [背包] 加载到 ${weapons.length} 件武器');
    for (final w in weapons) {
      print('⚔️ 武器详情：');
      print('   📛 名称：${w.name}');
      print('   🎚️ 阶数：${w.level}');
      print('   🧱 类型：${w.type}');
      print('   💥 攻击：${w.attackBoost}，🛡️ 防御：${w.defenseBoost}，❤️ 血量：${w.hpBoost}');
      print('   ✨ 特效：${w.specialEffects.join('，')}');
      print('   🖼️ 图标路径：${w.iconPath}');
      print('   🕒 炼制时间：${w.createdAt}');
    }

    for (final weapon in weapons) {
      final effect = weapon.specialEffects.isNotEmpty ? weapon.specialEffects.first : '';
      newItems.add(BeibaoItem(
        name: weapon.name,
        imagePath: weapon.iconPath, // ✅ 用真实图标路径
        quantity: 1,
        description: '阶数：${weapon.level}，效果：$effect',
      ));
    }

    setState(() {
      items = newItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_beibao.webp',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: BeibaoGridView(items: items),
          ),
          const BackButtonOverlay(),
        ],
      ),
    );
  }
}
