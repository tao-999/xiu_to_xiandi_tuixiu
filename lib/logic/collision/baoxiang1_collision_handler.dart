import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/resources_storage.dart';
import '../../services/treasure_chest_storage.dart';
import '../../utils/global_distance.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_static_decoration_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';

class Baoxiang1CollisionHandler {
  static Future<void> handle({
    required Vector2 playerLogicalPosition,
    required FloatingIslandStaticDecorationComponent chest,
    required Vector2 logicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) async {
    // ✅ 改用 tileKey 持久化判断
    final tileKey = chest.tileKey;
    if (tileKey == null) {
      print('❌ [Baoxiang1] 缺少 tileKey，跳过处理');
      return;
    }

    final isAlreadyOpened = await TreasureChestStorage.isOpenedTile(tileKey);
    if (isAlreadyOpened) return;

    final game = chest.findGame();
    if (game == null) {
      print('❌ [Baoxiang1] 未找到 game 实例');
      return;
    }

    final player = game.descendants().whereType<FloatingIslandPlayerComponent>().firstOrNull;
    if (player == null) {
      print('❌ [Baoxiang1] 未找到玩家组件');
      return;
    }

    player.stopMoving();
    print('🛑 [Baoxiang1] 玩家停止移动');

    // ✅ 距离决定奖励
    final double distance = computeGlobalDistancePx(comp: chest, game: game);
    final rand = Random();

    final count = distance > 10_000_000
        ? rand.nextInt(91) + 10    // 10 ~ 100
        : rand.nextInt(46) + 5;    // 5 ~ 50

    final lingShiTypes = LingShiType.values.toList();
    final lingShiType = lingShiTypes[rand.nextInt(lingShiTypes.length)];

    final field = lingShiFieldMap[lingShiType]!;
    ResourcesStorage.add(field, BigInt.from(count));

    // ✅ 标记为已开启（用 tileKey）
    TreasureChestStorage.markAsOpenedTile(tileKey);

    // ✅ 飘字提示
    final rewardText = '获得${lingShiNames[lingShiType]} ×$count 💰';
    final textPos = chest.worldPosition - Vector2(0, chest.size.y / 2 + 12);
    chest.parent?.add(
      FloatingTextComponent(
        text: rewardText,
        logicalPosition: textPos,
        color: Colors.orangeAccent,
      ),
    );

    print('🎁 [Baoxiang1] 奖励：$rewardText（距离=${distance.toStringAsFixed(0)}）');

    // ✅ 异步切换贴图
    Future.microtask(() async {
      try {
        final openedSprite = await Sprite.load('floating_island/beach_2_open.png');
        chest.sprite = openedSprite;
        print('🔁 [Baoxiang1] 宝箱贴图已更新为打开状态');
      } catch (e) {
        print('❌ [Baoxiang1] 切图失败：$e');
      }
    });

    // ✅ 刷新资源栏
    resourceBarKey.currentState?.refresh();
  }
}
