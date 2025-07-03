import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../services/resources_storage.dart';
import '../../services/terrain_event_storage_service.dart';
import '../../utils/lingshi_util.dart';
import 'floating_lingshi_popup_component.dart';

class RockTerrainEvent {
  static final Random _rand = Random();

  /// 🚀 按照距离区间抽取灵石品级
  static LingShiType pickLingShiType(double distance) {
    final roll = _rand.nextDouble();

    if (distance < 100_000) {
      // 100% 下品
      return LingShiType.lower;
    } else if (distance < 1_000_000) {
      // 50% 下品，50% 中品
      return roll < 0.5 ? LingShiType.lower : LingShiType.middle;
    } else if (distance < 10_000_000) {
      // 33% 下品、中品、上品
      if (roll < 1 / 3) {
        return LingShiType.lower;
      } else if (roll < 2 / 3) {
        return LingShiType.middle;
      } else {
        return LingShiType.upper;
      }
    } else {
      // 25% 四种
      if (roll < 0.25) {
        return LingShiType.lower;
      } else if (roll < 0.5) {
        return LingShiType.middle;
      } else if (roll < 0.75) {
        return LingShiType.upper;
      } else {
        return LingShiType.supreme;
      }
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
        quantity = max((base * 0.1).round(), 1);
        break;
      case LingShiType.upper:
        quantity = max((base * 0.05).round(), 1);
        break;
      case LingShiType.supreme:
        quantity = max((base * 0.01).round(), 1);
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

    final popup = FloatingLingShiPopupComponent(
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
