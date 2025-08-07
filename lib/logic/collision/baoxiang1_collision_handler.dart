import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/resources_storage.dart';
import '../../services/treasure_chest_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_static_decoration_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';

class Baoxiang1CollisionHandler {
  static void handle({
    required Vector2 playerLogicalPosition,
    required FloatingIslandStaticDecorationComponent chest,
    required Vector2 logicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 新增参数
  }) {
    // ✅ 判断是否已开启宝箱
    final isAlreadyOpened = TreasureChestStorage.isOpenedSync(chest.worldPosition);
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
    final distance = chest.worldPosition.length;
    final rand = Random();

    final count = distance > 10_000_000
        ? rand.nextInt(91) + 10    // 10 ~ 100
        : rand.nextInt(46) + 5;    // 5 ~ 50

    final lingShiTypes = LingShiType.values.toList();
    final lingShiType = lingShiTypes[rand.nextInt(lingShiTypes.length)];

    final field = lingShiFieldMap[lingShiType]!;
    ResourcesStorage.add(field, BigInt.from(count));

    // ✅ 标记宝箱已开启
    TreasureChestStorage.markAsOpened(chest.worldPosition);

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

    // ✅ 资源栏刷新（关键！）
    resourceBarKey.currentState?.refresh();
  }
}
