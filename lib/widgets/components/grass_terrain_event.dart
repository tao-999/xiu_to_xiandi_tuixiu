import 'dart:math';
import 'package:flame/game.dart';

import '../../services/resources_storage.dart';
import '../../services/terrain_event_storage_service.dart';
import 'floating_icon_text_popup_component.dart';

class GrassTerrainEvent {
  static final Random _rand = Random();

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    // 🌟2% 总概率
    final triggerRoll = _rand.nextDouble();
    if (triggerRoll >= 0.02) {
      return false;
    }

    // 🌟决定奖品
    final rewardRoll = _rand.nextDouble();
    final isFateCharm = rewardRoll < 0.75;

    final resourceKey = isFateCharm ? 'fateRecruitCharm' : 'recruitTicket';
    final rewardName = isFateCharm ? '资质券' : '招募券';
    final imagePath = isFateCharm
        ? 'assets/images/fate_recruit_charm.png'
        : 'assets/images/recruit_ticket.png';

    // ✅ 加资源
    await ResourcesStorage.add(resourceKey, BigInt.one);

    // ✅ 弹窗提示
    final popup = FloatingIconTextPopupComponent(
      text: '获得1张$rewardName',
      imagePath: imagePath,
      position: game.size / 2,
    );
    game.camera.viewport.add(popup);

    // ✅ 存储事件
    await TerrainEventStorageService.markTriggered(
      'grass',
      pos,
      'GAIN_$resourceKey'.toUpperCase(),
      data: {'quantity': 1},
      status: 'completed',
    );

    return true;
  }
}
