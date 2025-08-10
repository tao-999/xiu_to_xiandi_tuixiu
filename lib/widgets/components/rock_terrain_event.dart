import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../services/resources_storage.dart';
import '../../services/terrain_event_storage_service.dart';
import '../../utils/lingshi_util.dart';
import 'floating_icon_text_popup_component.dart';

class RockTerrainEvent {
  static final Random _rand = Random();

  /// 🚀 按照距离区间抽取灵石品级
  static LingShiType pickLingShiType(double distance) {
    final roll = _rand.nextDouble();

    if (distance < 100_000) {
      return LingShiType.lower;
    } else if (distance < 1_000_000) {
      // 下品70%、中品30%
      return roll < 0.7 ? LingShiType.lower : LingShiType.middle;
    } else if (distance < 10_000_000) {
      // 下70%、中15%、上15%
      if (roll < 0.7) return LingShiType.lower;
      if (roll < 0.85) return LingShiType.middle;
      return LingShiType.upper;
    } else {
      // 开启四种灵石概率
      if (roll < 0.7) return LingShiType.lower;
      if (roll < 0.85) return LingShiType.middle;
      if (roll < 0.95) return LingShiType.upper;
      return LingShiType.supreme;
    }
  }

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    final distance = pos.length;

    // 🌟5%概率触发
    final chanceRoll = _rand.nextDouble();
    if (chanceRoll >= 0.05) {
      return false;
    }

    // 🌟灵石品级
    final type = pickLingShiType(distance);

    // 🌟数量根据距离
    int base = (distance / 20).round();
    int quantity;

    switch (type) {
      case LingShiType.lower:
        quantity = max((base * 1.0).round(), 1);
        break;
      case LingShiType.middle:
        quantity = max((base * 0.001).round(), 1);
        break;
      case LingShiType.upper:
        quantity = max((base * 0.0005).round(), 1);
        break;
      case LingShiType.supreme:
        quantity = max((base * 0.0001).round(), 1);
        break;
    }

    // 🌟50%概率触发2倍
    final doubleReward = _rand.nextBool();
    if (doubleReward) {
      quantity *= 2;
    }

    final name = lingShiNames[type];
    final imagePath = getLingShiImagePath(type);
    final text = '$name x$quantity';

    // 🌟放在屏幕中心
    final centerPos = game.size / 2;

    final popup = FloatingIconTextPopupComponent(
      text: text,
      imagePath: imagePath,
      position: centerPos.clone(),
    );

    game.camera.viewport.add(popup);

    // 🌟写入事件
    await TerrainEventStorageService.markTriggered(
      'rock',
      pos,
      'MINE_SPIRIT_STONE',
      data: {
        'type': type.toString(),
        'quantity': quantity,
        'doubleReward': doubleReward,
      },
      status: 'completed',
    );

    // 🌟加到资源
    await ResourcesStorage.add(
      lingShiFieldMap[type]!,
      BigInt.from(quantity),
    );

    return true;
  }
}
