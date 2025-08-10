import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../data/all_pill_recipes.dart';
import '../../services/herb_material_service.dart';
import '../../services/terrain_event_storage_service.dart';
import 'floating_icon_text_popup_component.dart';

class ForestTerrainEvent {
  static final Random _rand = Random();

  // 🚀 阶数上界数组 (每阶区间递增1万)
  static final List<int> levelBounds = [
    10_000,
    30_000,
    60_000,
    100_000,
    150_000,
    210_000,
    280_000,
    360_000,
    450_000,
    550_000,
    660_000,
    780_000,
    910_000,
    1_050_000,
    1_200_000,
    1_360_000,
    1_530_000,
    1_710_000,
    1_900_000,
    2_100_000,
    2_310_000,
  ];

  // 🚀 根据距离返回最大阶数
  static int getLevelByDistance(double distance) {
    for (int i = 0; i < levelBounds.length; i++) {
      if (distance < levelBounds[i]) {
        return i + 1;
      }
    }
    return levelBounds.length;
  }

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    final distance = pos.length;

    // 🌟5%概率触发
    final chanceRoll = _rand.nextDouble();
    if (chanceRoll >= 0.05) {
      return false;
    }

    // 🌟根据距离确定最高阶
    final maxLevel = getLevelByDistance(distance);

    // 🌟随机1 ~ maxLevel
    final level = 1 + _rand.nextInt(maxLevel);

    // 🌟随机选草药
    final materials = levelMaterials[level - 1];
    final name = materials[_rand.nextInt(materials.length)];

    // 🌟数量1~2随机
    final quantity = 1 + _rand.nextInt(2);

    // 🌟加到背包
    await HerbMaterialService.add(name, quantity);

    // 🌟飘字提示
    final popup = FloatingIconTextPopupComponent(
      text: '采集到【$name】×$quantity',
      imagePath: 'assets/images/herbs/$name.png',
      position: game.size / 2,
    );
    game.camera.viewport.add(popup);

    // 🌟存储事件
    await TerrainEventStorageService.markTriggered(
      'forest',
      pos,
      'GATHER_HERB',
      data: {
        'herb': name,
        'level': level,
        'quantity': quantity,
      },
      status: 'completed',
    );

    return true;
  }
}
