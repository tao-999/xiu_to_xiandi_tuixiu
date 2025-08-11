// 📄 lib/logic/collision/boss2_collision_handler.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

import '../combat/boss_reward_registry.dart'; // BossKillContext
import '../../services/dead_boss_storage.dart';
import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

/// ⚠️ 纯奖励逻辑：不包含“碰撞受伤/推开/嘲讽/冷却”
/// 使用：Boss 被打到 0 血时，BossRewardRegistry.dispatch() 会调这里的 onKilled()
class Boss2CollisionHandler {
  /// Boss2 死亡结算（清理 + 掉落 + 飘窗 + 刷新资源条）
  static Future<void> onKilled(
      BossKillContext ctx,
      FloatingIslandDynamicMoverComponent boss,
      ) async {
    debugPrint('☠️ [Boss2] onKilled() tileKey=${boss.spawnedTileKey} at ${boss.logicalPosition}');

    // 2) 视觉清理
    boss.removeFromParent();
    boss.hpBar?.removeFromParent(); boss.hpBar = null;
    boss.label?.removeFromParent(); boss.label = null;
    boss.isDead = true;

    // 3) 掉落规则（Boss2：无“极品”档）
    final rand = Random();
    final r = rand.nextDouble();
    late LingShiType type;
    if (r < 0.7) {
      type = LingShiType.lower;
    } else if (r < 0.9) {
      type = LingShiType.middle;
    } else {
      type = LingShiType.upper;
    }

    final bossAtk = (boss.atk ?? 10).toInt();
    late int count;
    switch (type) {
      case LingShiType.lower:   count = bossAtk; break;
      case LingShiType.middle:  count = (bossAtk ~/ 6).clamp(1, 9999); break;
      case LingShiType.upper:   count = (bossAtk ~/ 24).clamp(1, 9999); break;
      case LingShiType.supreme: count = 0; break; // Boss2 不会走到这里
    }

    // 4) 飘窗 + 入库 + 刷 UI
    final rewardText = '+$count ${lingShiNames[type] ?? "灵石"}';
    final centerPos = boss.findGame()!.size / 2;

    boss.findGame()!.camera.viewport.add(
      FloatingIconTextPopupComponent(
        text: rewardText,
        imagePath: getLingShiImagePath(type),
        position: centerPos,
      ),
    );

    final field = lingShiFieldMap[type]!;
    ResourcesStorage.add(field, BigInt.from(count));
    ctx.resourceBarKey.currentState?.refresh();

    debugPrint('🎁 [Boss2] reward=$rewardText');
  }
}
