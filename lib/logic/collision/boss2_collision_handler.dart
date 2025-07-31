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

class Boss2CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent boss,
    required Vector2 logicalOffset,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 注入 key
  }) {
    print('🐉 [Boss2] 玩家靠近 Boss → pos=${boss.logicalPosition}');
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
          color: Colors.redAccent,
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
          boss.hpBar = null;
          boss.label?.removeFromParent();
          boss.label = null;
          boss.isDead = true;

          print('☠️ Boss2 已被击败！tileKey=$tileKey');

          // ✅ 奖励逻辑（不含极品）
          final r = rand.nextDouble();
          late LingShiType type;
          if (r < 0.7) {
            type = LingShiType.lower;
          } else if (r < 0.9) {
            type = LingShiType.middle;
          } else {
            type = LingShiType.upper;
          }

          final bossAtk = boss.atk ?? 10;
          late int count;
          switch (type) {
            case LingShiType.lower:
              count = bossAtk.toInt();
              break;
            case LingShiType.middle:
              count = (bossAtk ~/ 6).clamp(1, 9999);
              break;
            case LingShiType.upper:
              count = (bossAtk ~/ 24).clamp(1, 9999);
              break;
            case LingShiType.supreme:
              count = 0;
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
          resourceBarKey.currentState?.refresh(); // ✅ 刷新资源栏
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
          "你这是送命来了？", "回家吃奶吧。", "不自量力！", "见我不跪？", "你太嫩了！",
        ];
        final tauntListAngry = [
          "竟然伤了我！", "我要把你碾成齑粉！", "你惹怒我了！", "区区蝼蚁，也敢逆天？",
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
