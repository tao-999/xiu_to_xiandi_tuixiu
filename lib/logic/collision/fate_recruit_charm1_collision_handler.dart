import 'package:flutter/material.dart';
import '../../services/fate_recruit_charm_storage.dart';
import '../../services/resources_storage.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

class FateRecruitCharm1CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent charm,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    // ✅ 提前打印标识
    final tileKey = charm.spawnedTileKey;
    print('💫 [FateRecruitCharm1] 玩家拾取资质券 → pos=${player.logicalPosition}');
    print('🎯 tileKey = $tileKey');
    print('⏳ 当前 cooldown = ${charm.collisionCooldown.toStringAsFixed(2)} 秒');

    // ✅ 第一次判断，已死或冷却中
    if (charm.isDead || charm.collisionCooldown > 0) return;

    // ✅ 🔐 第一次进入就锁定，防止并发
    charm.isDead = true;
    charm.collisionCooldown = double.infinity;

    // ✅ 再异步判断是否已被收集
    FateRecruitCharmStorage.isCollected(tileKey).then((collected) async {
      if (collected) {
        print('⚠️ 该资质券已被收集: $tileKey');
        return;
      }

      await FateRecruitCharmStorage.markCollected(tileKey);
      await ResourcesStorage.add('fateRecruitCharm', BigInt.one);

      resourceBarKey.currentState?.refresh();

      final game = charm.findGame()!;
      final centerPos = game.size / 2;
      game.add(FloatingIconTextPopupComponent(
        text: '获得资质券 ×1',
        imagePath: 'assets/images/fate_recruit_charm.png',
        position: centerPos,
      ));

      // ✅ 彻底移除
      charm.removeFromParent();
      charm.label?.removeFromParent();
      charm.label = null;

      // ⏱️ 2秒后清除 cooldown（理论不会再触发）
      Future.delayed(const Duration(seconds: 2), () {
        charm.collisionCooldown = 0;
      });
    });
  }
}

