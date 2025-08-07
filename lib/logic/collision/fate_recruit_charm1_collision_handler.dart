import 'package:flutter/material.dart';
import '../../services/fate_recruit_charm_storage.dart';
import '../../services/resources_storage.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

class FateRecruitCharm1CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent charm,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 加了
  }) {
    print('💫 [FateRecruitCharm1] 玩家拾取资质券 → pos=${player.logicalPosition}');
    print('⏳ collisionCooldown = ${charm.collisionCooldown.toStringAsFixed(2)} 秒');

    if (charm.isDead || charm.collisionCooldown > 0) return;
    charm.collisionCooldown = double.infinity;

    final tileKey = charm.spawnedTileKey;

    FateRecruitCharmStorage.isCollected(tileKey).then((collected) async {
      if (collected) return;

      await FateRecruitCharmStorage.markCollected(tileKey);
      await ResourcesStorage.add('fateRecruitCharm', BigInt.one);

      // ✅ 刷新资源条
      resourceBarKey.currentState?.refresh();

      final game = charm.findGame()!;
      final centerPos = game.size / 2;
      game.add(FloatingLingShiPopupComponent(
        text: '获得资质券 ×1',
        imagePath: 'assets/images/fate_recruit_charm.png',
        position: centerPos,
      ));

      charm.isDead = true;
      charm.removeFromParent();
      charm.label?.removeFromParent();
      charm.label = null;

      Future.delayed(const Duration(seconds: 2), () {
        charm.collisionCooldown = 0;
      });
    });
  }
}
