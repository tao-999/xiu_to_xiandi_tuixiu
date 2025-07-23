// lib/widgets/components/flower_field_terrain_event.dart
import 'dart:math';
import 'package:flame/game.dart';

import '../../services/favorability_material_service.dart';
import '../../services/terrain_event_storage_service.dart';
import '../components/floating_lingshi_popup_component.dart';
import '../../data/favorability_data.dart'; // 🌟导入数据模型

class FlowerFieldTerrainEvent {
  static final Random _rand = Random();

  static Future<bool> trigger(
      Vector2 pos,
      FlameGame game,
      ) async {
    // 🌸4%概率
    final triggerRoll = _rand.nextDouble();
    if (triggerRoll >= 0.04) {
      return false;
    }

    // 🌸随机1-30
    final materialIndex = _rand.nextInt(30) + 1;

    final item = FavorabilityData.getByIndex(materialIndex);

    // ✅ 增加材料库存
    await FavorabilityMaterialService.addMaterial(materialIndex, 1);

    // ✅ 弹窗提示
    final popup = FloatingLingShiPopupComponent(
      text: '获得1个 ${item.name}',
      imagePath: item.assetPath,
      position: game.size / 2,
    );
    game.camera.viewport.add(popup);

    // ✅ 存储事件
    await TerrainEventStorageService.markTriggered(
      'flower_field',
      pos,
      'GAIN_FAVOR_MATERIAL',
      data: {
        'materialIndex': materialIndex,
        'quantity': 1,
        'favorValue': item.favorValue,
      },
      status: 'completed',
    );

    return true;
  }
}
