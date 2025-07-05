import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../services/terrain_event_storage_service.dart';
import '../../services/refine_material_service.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';

class VolcanicTerrainEvent {
  static final Random _rand = Random();

  // ✅ 等差数列分阶边界
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

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    final distance = pos.length;

    // 🌟先判定是否触发
    final chanceRoll = _rand.nextDouble();
    if (chanceRoll >= 0.04) {
      return false;
    }

    // 🌟计算最大阶数
    int maxLevel = 1;
    for (int i = 0; i < levelBounds.length; i++) {
      if (distance <= levelBounds[i]) {
        maxLevel = i + 1;
        break;
      }
    }

    // 如果超过最大，固定为21阶
    if (distance > levelBounds.last) {
      maxLevel = 21;
    }

    // 🌟从1~maxLevel随机一个阶
    final selectedLevel = _rand.nextInt(maxLevel) + 1;

    // 🌟获取该阶所有材料
    final materials = RefineMaterialService.getMaterialsForLevel(selectedLevel);
    final material = materials[_rand.nextInt(materials.length)];

    // 🌟数量1-2
    final quantity = _rand.nextInt(2) + 1;

    // 🌟提示文本
    final text = '${material.name} x$quantity';

    // 🌟直接放在屏幕中心
    final centerPos = game.size / 2;

    final popup = FloatingLingShiPopupComponent(
      text: text,
      imagePath: material.image,
      position: centerPos.clone(),
    );

    // 🌟挂在UI层（Viewport）
    game.camera.viewport.add(popup);

    // 🌟存储事件
    await TerrainEventStorageService.markTriggered(
      'volcanic',
      pos,
      'COLLECT_REFINE_MATERIAL',
      data: {
        'material': material.name,
        'level': selectedLevel,
        'quantity': quantity,
      },
      status: 'completed',
    );

    // 🌟存仓库
    await RefineMaterialService.add(material.name, quantity);

    return true;
  }
}
