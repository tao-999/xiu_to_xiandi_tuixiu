// 📂 lib/logic/collision/boss3_collision_handler.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../services/dead_boss_storage.dart';
import '../../services/player_storage.dart';
import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/effects/logical_move_effect.dart';
import '../../widgets/components/resource_bar.dart';

class Boss3CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent boss,
    required Vector2 logicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 注入 key
  }) {
    print('🐲 [Boss3] 玩家靠近 Boss → pos=${boss.logicalPosition}');
    print('🧾 Boss 属性：HP=${boss.currentHp}/${boss.hp}, ATK=${boss.atk}, DEF=${boss.def}');
    print('⏳ collisionCooldown = ${boss.collisionCooldown.toStringAsFixed(2)} 秒');

    final rand = Random();

    // ✅【1】Boss 受击（带冷却控制）
    if (boss.collisionCooldown <= 0) {
      boss.collisionCooldown = double.infinity;

      PlayerStorage.getPlayer().then((playerData) {
        if (playerData == null) return;

        final playerAtk = PlayerStorage.getAtk(playerData);
        final bossDef = boss.def ?? 0;
        final bossHp = boss.currentHp;

        final damage = (playerAtk - bossDef).clamp(1, double.infinity).toDouble();
        final newHp = (bossHp - damage).clamp(0, boss.hp!).toDouble();
        boss.currentHp = newHp;

        boss.hpBar?.setStats(
          currentHp: newHp.toInt(),
          maxHp: boss.hp!.toInt(),
          atk: boss.atk?.toInt() ?? 0,
          def: boss.def?.toInt() ?? 0,
        );

        final hitPos = boss.logicalPosition - Vector2(0, boss.size.y / 2 + 8);
        boss.parent?.add(FloatingTextComponent(
          text: '-${damage.toInt()}',
          logicalPosition: hitPos,
          color: Colors.deepOrange,
          fontSize: 18,
        ));

        if (newHp <= 0) {
          final tileKey = boss.spawnedTileKey;
          final deathPos = boss.logicalPosition.clone();

          if (boss.type != null) {
            DeadBossStorage.markDeadBoss(
              tileKey: tileKey,
              position: deathPos,
              bossType: boss.type!,
              size: boss.size.clone(),
            );
          }

          boss.removeFromParent();
          boss.hpBar?.removeFromParent();
          boss.label?.removeFromParent();
          boss.hpBar = null;
          boss.label = null;
          boss.isDead = true;

          print('☠️ Boss3 已被击败！tileKey=$tileKey');

          // 🎁【奖励逻辑占位】

          final r = rand.nextDouble();
          late LingShiType type;

          if (r < 0.60) {
            type = LingShiType.lower;
          } else if (r < 0.85) {
            type = LingShiType.middle;
          } else if (r < 0.95) {
            type = LingShiType.upper;
          } else {
            type = LingShiType.supreme;
          }

          final bossAtk = boss.atk ?? 10;
          late int count;

          switch (type) {
            case LingShiType.lower:
              count = bossAtk.toInt(); // 💥 下品 = atk
              break;
            case LingShiType.middle:
              count = (bossAtk ~/ 5).clamp(1, 9999); // ⚡️ 中品 = atk / 5
              break;
            case LingShiType.upper:
              count = (bossAtk ~/ 15).clamp(1, 9999); // 🔥 上品 = atk / 15 ✅ 提高
              break;
            case LingShiType.supreme:
              count = (bossAtk ~/ 40).clamp(1, 9999); // 🧬 极品 = atk / 40 ✅ 提高
              break;
          }

          final rewardText = '+$count ${lingShiNames[type] ?? "灵石"}';
          final centerPos = boss.findGame()!.size / 2;

          boss.findGame()!.camera.viewport.add(FloatingLingShiPopupComponent(
            text: rewardText,
            imagePath: getLingShiImagePath(type),
            position: centerPos,
          ));

          final field = lingShiFieldMap[type]!;
          ResourcesStorage.add(field, BigInt.from(count));
          resourceBarKey.currentState?.refresh();

          resourceBarKey.currentState?.refresh();
        }

        Future.delayed(const Duration(seconds: 1), () {
          boss.collisionCooldown = 0;
        });
      });
    }

    // ✅【2】弹开逻辑
    final pushDistance = 10 + rand.nextDouble() * 10;
    final direction = (boss.logicalPosition - player.logicalPosition).normalized();

    final bossTargetPos = boss.logicalPosition + direction * pushDistance;
    boss.isMoveLocked = true;
    boss.add(LogicalMoveEffect(
      npc: boss,
      targetPosition: bossTargetPos,
      controller: EffectController(
        duration: 0.4,
        curve: Curves.easeOutQuad,
      ),
    ));

    final playerTargetPos = player.logicalPosition - direction * pushDistance;
    player.moveTo(playerTargetPos);

    // ✅【3】嘴臭逻辑
    if (boss.tauntCooldown <= 0) {
      boss.tauntCooldown = double.infinity;

      PlayerStorage.getPlayer().then((playerData) {
        if (playerData == null) return;

        final tauntListWeak = [
          "杂鱼也敢闯此地？",
          "来送人头的吗？",
          "你的修为令我发笑。",
          "你修炼的是滑稽术吧？",
          "别来丢人现眼了。",
          "灵根未开，滚回娘胎！",
          "你敢碰我？勇气可嘉。",
          "修炼二十载，换来一身菜。",
          "你这招，我五岁就会了。",
          "可怜的蝼蚁，还想翻天？",
        ];

        final tauntListAngry = [
          "你竟敢伤我！",
          "我要让你生不如死！",
          "本尊今日定要诛你九族！",
          "你触怒了天威！",
          "我怒火滔天，众生避退！",
          "你的死期已到！",
          "再无回头路了！",
          "你这是在找死！",
          "小小修士，也敢动我？",
          "不杀你难平我心头之恨！",
        ];

        final playerAtk = PlayerStorage.getAtk(playerData);
        final playerDef = PlayerStorage.getDef(playerData);
        final bossAtk = boss.atk ?? 0;
        final bossDef = boss.def ?? 0;

        final playerPower = playerAtk + playerDef;
        final bossPower = bossAtk + bossDef;

        final isPlayerWeaker = playerPower <= bossPower;
        final tauntList = isPlayerWeaker ? tauntListWeak : tauntListAngry;
        final taunt = tauntList[rand.nextInt(tauntList.length)];

        final tauntPos = boss.logicalPosition - Vector2(0, boss.size.y / 2 + 8);
        boss.parent?.add(FloatingTextComponent(
          text: taunt,
          logicalPosition: tauntPos,
          color: Colors.black,
        ));

        Future.delayed(const Duration(seconds: 5), () {
          boss.tauntCooldown = 0;
        });
      });
    }
  }
}
