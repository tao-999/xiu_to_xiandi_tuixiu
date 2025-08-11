// 📂 lib/logic/collision/boss3_collision_handler.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

import '../combat/boss_reward_registry.dart'; // BossKillContext
import '../../services/dead_boss_storage.dart';
import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';

/// ⚠️ 纯奖励逻辑：不包含“碰撞受伤/推开/嘲讽/冷却”
/// 使用：Boss 被打到 0 血时，由 BossRewardRegistry.dispatch() 调用这里的 onKilled()
class Boss3CollisionHandler {
  /// Boss3 死亡结算（清理 + 掉落 + 飘窗 + 刷新资源条）
  static Future<void> onKilled(
      BossKillContext ctx,
      FloatingIslandDynamicMoverComponent boss,
      ) async {
    debugPrint('☠️ [Boss3] onKilled() tileKey=${boss.spawnedTileKey} at ${boss.logicalPosition}');

    // 2) 视觉清理
    boss.removeFromParent();
    boss.hpBar?.removeFromParent(); boss.hpBar = null;
    boss.label?.removeFromParent(); boss.label = null;
    boss.isDead = true;

    // 3) 掉落规则（Boss3 专属：更高档位概率 & 提高中/上/极品数量）
    final rand = Random();
    final r = rand.nextDouble();

    late LingShiType type;
    if (r < 0.60) {
      type = LingShiType.lower;   // 60%
    } else if (r < 0.85) {
      type = LingShiType.middle;  // 25%
    } else if (r < 0.95) {
      type = LingShiType.upper;   // 10%
    } else {
      type = LingShiType.supreme; // 5%
    }

    final bossAtk = (boss.atk ?? 10).toInt();
    late int count;
    switch (type) {
      case LingShiType.lower:
        count = bossAtk;                         // 下品 = atk
        break;
      case LingShiType.middle:
        count = (bossAtk ~/ 5).clamp(1, 9999);  // 中品 = atk / 5（提高）
        break;
      case LingShiType.upper:
        count = (bossAtk ~/ 15).clamp(1, 9999); // 上品 = atk / 15（提高）
        break;
      case LingShiType.supreme:
        count = (bossAtk ~/ 40).clamp(1, 9999); // 极品 = atk / 40（提高）
        break;
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

    debugPrint('🎁 [Boss3] reward=$rewardText');
  }
}
