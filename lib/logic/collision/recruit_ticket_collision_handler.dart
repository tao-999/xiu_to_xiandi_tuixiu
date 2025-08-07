import 'package:flutter/material.dart';

import '../../services/resources_storage.dart';
import '../../services/recruit_ticket_storage.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

class RecruitTicketCollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent charm,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    print('🎫 [RecruitTicket] 玩家拾取招募券 → pos=${player.logicalPosition}');
    print('⏳ collisionCooldown = ${charm.collisionCooldown.toStringAsFixed(2)} 秒');

    if (charm.isDead || charm.collisionCooldown > 0) return;
    charm.collisionCooldown = double.infinity;

    final tileKey = charm.spawnedTileKey;

    RecruitTicketStorage.isCollected(tileKey).then((collected) async {
      if (collected) return;

      // ✅ 标记为已拾取
      await RecruitTicketStorage.markCollected(tileKey);

      // ✅ 添加资源
      await ResourcesStorage.add('recruitTicket', BigInt.one);

      // ✅ 飘字提示 + 图标展示
      final game = charm.findGame()!;
      final centerPos = game.size / 2;
      game.add(FloatingLingShiPopupComponent(
        text: '获得招募券 ×1',
        imagePath: 'assets/images/recruit_ticket.png',
        position: centerPos,
      ));

      // ✅ 刷新资源条
      resourceBarKey.currentState?.refresh();

      // ✅ 移除道具
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
