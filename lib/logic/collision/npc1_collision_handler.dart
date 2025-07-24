import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/effects/logical_move_effect.dart';

class Npc1CollisionHandler {
  static final List<String> taunts = [
    "滚开！", "你算哪根葱？", "别来碍眼！", "找抽是不是？", "你有病啊？", "离远点！",
    "再碰试试！", "不知死活！", "废物！", "真烦人！", "别碰我！", "想死啊？",
    "蠢货！", "没长眼？", "真讨厌！", "走开！", "不配和我比！", "自取其辱！",
    "死远点！", "啧，丢人！", "好胆再来！", "再靠近试试！", "不自量力！",
    "你也配？", "我看你是欠收拾！", "没点本事还嚷嚷？", "滚蛋！", "你找错人了！",
    "想清楚后果！", "自取灭亡！", "谁给你的勇气？", "白痴！", "下一个！",
    "真没劲！", "愚蠢至极！", "小丑罢了！", "给你脸了？", "别蹭存在感！",
    "你瞎啊？", "有本事放马过来！", "识相的快滚！", "不怕死就上！", "你太弱了！",
    "再瞪我试试！", "我一根手指头捏死你！", "不服来战！", "快滚，免得丢命！",
    "就你？不够看！", "活该被虐！", "可怜虫一个！", "小小蝼蚁！", "这智商，堪忧！",
  ];

  static void handle({
    required Vector2 playerLogicalPosition,
    required FloatingIslandDynamicMoverComponent npc,
    required Vector2 logicalOffset, // ✅ 当前视口偏移
  }) {
    // 🚀 计算弹开目标逻辑坐标
    final rand = Random();
    final pushDistance = 50 + rand.nextDouble() * 50; // [50, 100)
    final direction = (npc.logicalPosition - playerLogicalPosition).normalized();
    final targetLogicalPos = npc.logicalPosition + direction * pushDistance;


    // ✅ 设置为弹开状态，防止游走
    npc.isMoveLocked = true;

    // 🚀 添加逻辑坐标动画
    npc.add(
      LogicalMoveEffect(
        npc: npc,
        targetPosition: targetLogicalPos,
        controller: EffectController(
          duration: 0.4,
          curve: Curves.easeOutQuad,
        ),
      ),
    );

    // 💬 飘字嘴臭（冷却）
    if (npc.tauntCooldown <= 0) {
      npc.tauntCooldown = 5.0;

      final rand = Random();
      final roll = rand.nextDouble();
      final distance = npc.logicalPosition.length;

      if (roll < 0.1) {
        // 🎁 10% 概率 → 奖励灵石
        LingShiType lingShiType;
        int minCount, maxCount;

        if (distance < 100_000) {
          lingShiType = LingShiType.lower;
          minCount = 1;
          maxCount = 10;
        } else if (distance < 1_000_000) {
          lingShiType = rand.nextDouble() < 0.8 ? LingShiType.lower : LingShiType.middle;
          minCount = 10;
          maxCount = 20;
        } else if (distance < 10_000_000) {
          final r = rand.nextDouble();
          lingShiType = r < 0.6 ? LingShiType.lower : (r < 0.9 ? LingShiType.middle : LingShiType.upper);
          minCount = 20;
          maxCount = 40;
        } else {
          final r = rand.nextDouble();
          lingShiType = r < 0.4
              ? LingShiType.lower
              : (r < 0.7 ? LingShiType.middle : (r < 0.9 ? LingShiType.upper : LingShiType.supreme));
          minCount = 40;
          maxCount = 80;
        }

        final count = rand.nextInt(maxCount - minCount + 1) + minCount;
        final rewardText = '+$count ${lingShiNames[lingShiType]!}';
        final game = npc.findGame()!;
        final centerPos = game.size / 2;

        // ✅ 加入灵石奖励组件
        game.camera.viewport.add(FloatingLingShiPopupComponent(
          text: rewardText,
          imagePath: getLingShiImagePath(lingShiType),
          position: centerPos.clone(),
        ));

        final field = lingShiFieldMap[lingShiType]!;
        ResourcesStorage.add(field, BigInt.from(count));

      } else {
        // 🗯️ 嘴臭弹幕
        final taunt = taunts[rand.nextInt(taunts.length)];
        final tauntPos = targetLogicalPos.clone() - Vector2(0, npc.size.y / 2 + 8);

        npc.parent?.add(FloatingTextComponent(
          text: taunt,
          logicalPosition: tauntPos,
          color: Colors.redAccent,
        ));

      }
    }

  }
}
