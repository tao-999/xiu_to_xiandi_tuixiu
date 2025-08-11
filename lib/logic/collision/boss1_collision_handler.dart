// 📄 lib/logic/collision/boss1_collision_handler.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

import '../combat/boss_reward_registry.dart';                 // BossKillContext
import '../../services/dead_boss_storage.dart';
import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

/// ⚠️ 纯奖励逻辑：不再包含“碰撞受伤/推开/嘲讽/冷却”
/// 使用：Boss 被打到 0 血时，调用 BossRewardRegistry.dispatch() → 这里的 onKilled()
class Boss1CollisionHandler {
  /// Boss1 死亡结算（清理 + 掉落 + 飘窗 + 刷新资源条）
  static Future<void> onKilled(
      BossKillContext ctx,
      FloatingIslandDynamicMoverComponent boss,
      ) async {
    debugPrint('☠️ [Boss1] onKilled() tileKey=${boss.spawnedTileKey} at ${boss.logicalPosition}');

    // 2) 视觉清理
    boss.removeFromParent();
    boss.hpBar?.removeFromParent(); boss.hpBar = null;
    boss.label?.removeFromParent(); boss.label = null;
    boss.isDead = true;

    // 3) 掉落规则（沿用你之前 Boss1 的概率 & 数量算法）
    final rand = Random();
    final r = rand.nextDouble();

    // 概率：0.7/0.2/0.08/0.02
    late LingShiType type;
    if (r < 0.7) {
      type = LingShiType.lower;
    } else if (r < 0.9) {
      type = LingShiType.middle;
    } else if (r < 0.98) {
      type = LingShiType.upper;
    } else {
      type = LingShiType.supreme;
    }

    // 数量：基于 boss.atk
    final bossAtk = (boss.atk ?? 10).toInt();
    late int count;
    switch (type) {
      case LingShiType.lower:   count = bossAtk; break;
      case LingShiType.middle:  count = (bossAtk ~/ 8).clamp(1, 999999); break;
      case LingShiType.upper:   count = (bossAtk ~/ 32).clamp(1, 999999); break;
      case LingShiType.supreme: count = (bossAtk ~/ 128).clamp(1, 999999); break;
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

    // 刷资源条
    ctx.resourceBarKey.currentState?.refresh();

    debugPrint('🎁 [Boss1] reward=$rewardText');
  }
}
