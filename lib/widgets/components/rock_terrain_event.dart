import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../services/resources_storage.dart';
import '../../services/terrain_event_storage_service.dart';
import '../../utils/lingshi_util.dart';
import 'floating_lingshi_popup_component.dart';

class RockTerrainEvent {
  static final Random _rand = Random();

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    final distance = pos.length;

    // 🌟先判定是否触发
    final chanceRoll = _rand.nextDouble();
    if (chanceRoll >= 0.10) {
      return false;
    }

    // 🌟随机灵石品级概率（你的逻辑保留）
    final roll = _rand.nextDouble();
    LingShiType type;
    if (roll < 0.01) {
      type = LingShiType.supreme;
    } else if (roll < 0.10) {
      type = LingShiType.upper;
    } else if (roll < 0.30) {
      type = LingShiType.middle;
    } else {
      type = LingShiType.lower;
    }

    // 🌟数量根据距离
    int base = (distance / 20).round();
    int quantity;

    switch (type) {
      case LingShiType.lower:
        quantity = max((base * 1.0).round(), 1);
        break;
      case LingShiType.middle:
        quantity = max((base * 0.1).round(), 1);
        break;
      case LingShiType.upper:
        quantity = max((base * 0.05).round(), 1);
        break;
      case LingShiType.supreme:
        quantity = max((base * 0.01).round(), 1);
        break;
    }

    if (quantity <= 0) {
      quantity = 1;
    }

    final name = lingShiNames[type];
    final imagePath = getLingShiImagePath(type);
    final text = '$name x$quantity';

    // 🌟直接放在屏幕中心
    final centerPos = game.size / 2;

    final popup = FloatingLingShiPopupComponent(
      text: text,
      imagePath: imagePath,
      position: centerPos.clone(),
    );

    // 🌟挂在UI层（Viewport）
    game.camera.viewport.add(popup);

    await TerrainEventStorageService.markTriggered(
      'rock',
      pos,
      'MINE_SPIRIT_STONE',
      data: {
        'type': type.toString(),
        'quantity': quantity,
      },
      status: 'completed',
    );

    await ResourcesStorage.add(
      lingShiFieldMap[type]!,
      BigInt.from(quantity),
    );

    return true;
  }
}
