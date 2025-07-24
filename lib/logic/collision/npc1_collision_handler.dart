import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../widgets/components/floating_island_dynamic_mover_component.dart';
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

    // 🧾 打印调试信息
    print('📦 [Npc1弹开] ${npc.labelText ?? 'NPC'}');
    print('┣ 🧍 当前逻辑坐标: ${npc.logicalPosition}');
    print('┣ 🎯 弹开目标逻辑坐标: $targetLogicalPos');
    print('┣ 🎥 logicalOffset: $logicalOffset');

    // 💬 飘字嘴臭（冷却）
    if (npc.tauntCooldown <= 0) {
      npc.tauntCooldown = 5.0;

      final taunt = taunts[Random().nextInt(taunts.length)];

      // 🛠️ FIX: 使用目标逻辑坐标作为飘字位置，避免旧坐标误差
      final tauntPos = targetLogicalPos.clone() - Vector2(0, npc.size.y / 2 + 8);

      print('💬 [Npc1飘字] text="$taunt"');
      print('┣ 📍 逻辑坐标: $tauntPos');

      npc.parent?.add(FloatingTextComponent(
        text: taunt,
        logicalPosition: tauntPos,
        color: Colors.redAccent,
      ));
    }
  }
}
