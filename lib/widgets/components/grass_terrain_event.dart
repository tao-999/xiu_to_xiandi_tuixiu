import 'dart:math';
import 'package:flame/game.dart';

import '../../services/resources_storage.dart';
import '../../services/terrain_event_storage_service.dart';
import 'floating_lingshi_popup_component.dart';

class GrassTerrainEvent {
  static final Random _rand = Random();

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    // 🌟1%概率
    final chanceRoll = _rand.nextDouble();
    if (chanceRoll >= 0.01) {
      return false;
    }

    // 🌟增加1张资质券
    await ResourcesStorage.add('fateRecruitCharm', BigInt.one);

    // 🌟弹窗提示
    final popup = FloatingLingShiPopupComponent(
      text: '获得1张资质券',
      imagePath: 'assets/images/fate_recruit_charm.png',
      position: game.size / 2,
    );
    game.camera.viewport.add(popup);

    // 🌟存储事件
    await TerrainEventStorageService.markTriggered(
      'grass',
      pos,
      'GAIN_FATE_CHARM',
      data: {
        'quantity': 1,
      },
      status: 'completed',
    );

    return true;
  }
}
