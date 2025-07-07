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
    print('🌸[FlowerFieldTerrainEvent] 尝试触发事件...');
    // 🌸4%概率
    final triggerRoll = _rand.nextDouble();
    print('🎲 随机数(0~1): $triggerRoll');
    if (triggerRoll >= 0.04) {
      print('❌ 未触发事件 (小于4%概率)');
      return false;
    }

    // 🌸随机1-30
    final materialIndex = _rand.nextInt(30) + 1;
    print('✅ 事件触发，抽取材料 index: $materialIndex');

    final item = FavorabilityData.getByIndex(materialIndex);
    print('🧩 材料详情: 名称="${item.name}", 好感度=${item.favorValue}, 图片路径=${item.assetPath}');

    // ✅ 增加材料库存
    await FavorabilityMaterialService.addMaterial(materialIndex, 1);
    print('📦 已增加库存: +1');

    // ✅ 弹窗提示
    final popup = FloatingLingShiPopupComponent(
      text: '获得1个 ${item.name}',
      imagePath: item.assetPath,
      position: game.size / 2,
    );
    game.camera.viewport.add(popup);
    print('✨ 弹窗已添加到画面');

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
    print('📝 事件已存储');

    return true;
  }
}
