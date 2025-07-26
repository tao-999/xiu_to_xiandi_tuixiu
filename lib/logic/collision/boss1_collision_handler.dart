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

class Boss1CollisionHandler {

  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent boss,
    required Vector2 logicalOffset,
  }) {
    print('👹 [Boss1] 玩家靠近 Boss → pos=${boss.logicalPosition}');
    print('🧾 Boss 属性：HP=${boss.hp}, ATK=${boss.atk}, DEF=${boss.def}');
    print('⏳ collisionCooldown = ${boss.collisionCooldown.toStringAsFixed(2)} 秒');

    final rand = Random();

    // ✅【1】Boss 受击（带冷却控制）
    if (boss.collisionCooldown <= 0) {
      boss.collisionCooldown = double.infinity;

      PlayerStorage.getPlayer().then((playerData) {
        if (playerData == null) return;

        final playerAtk = PlayerStorage.getAtk(playerData);
        final bossDef = boss.def ?? 0;
        final bossHp = boss.hp ?? 0;

        final damage = (playerAtk - bossDef).clamp(1, double.infinity).toDouble();
        final newHp = (bossHp - damage).clamp(0, double.infinity).toDouble();
        boss.hp = newHp;

        // ✅ 同步血条（用 newHp 当 maxHp）
        boss.hpBar?.setStats(
          currentHp: newHp.toInt(),
          maxHp: boss.hp!.toInt(), // 用最新 hp，当作 maxHp
          atk: boss.atk?.toInt() ?? 0,
          def: boss.def?.toInt() ?? 0,
        );

        // ✅ 飘字
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

          // ✅ 记录死亡 tileKey 和坐标
          if (boss.type != null) {
            DeadBossStorage.markDeadBoss(
              tileKey: boss.spawnedTileKey,
              position: boss.logicalPosition.clone(),
              bossType: boss.type!,
              size: boss.size.clone(),
            );
          }

          // ✅ 移除boss组件
          boss.removeFromParent();
          boss.hpBar?.removeFromParent();
          boss.hpBar = null;
          boss.label?.removeFromParent();
          boss.label = null;
          boss.isDead = true;

          print('☠️ Boss1 已被击败！tileKey=$tileKey');

          // ✅ 发放灵石奖励
          final rand = Random();
          final r = rand.nextDouble(); // 概率衰减判断
          LingShiType type;
          if (r < 0.7) {
            type = LingShiType.lower;
          } else if (r < 0.9) {
            type = LingShiType.middle;
          } else if (r < 0.98) {
            type = LingShiType.upper;
          } else {
            type = LingShiType.supreme;
          }

          final bossAtk = boss.atk ?? 10;
          late int count;
          switch (type) {
            case LingShiType.lower:
              count = bossAtk.toInt(); // ✅ 转换为 int
              break;
            case LingShiType.middle:
              count = (bossAtk ~/ 8).clamp(1, 9999);
              break;
            case LingShiType.upper:
              count = (bossAtk ~/ 32).clamp(1, 9999);
              break;
            case LingShiType.supreme:
              count = (bossAtk ~/ 128).clamp(1, 9999);
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
        }

        // ✅ 延迟解锁 cooldown
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
    boss.add(
      LogicalMoveEffect(
        npc: boss,
        targetPosition: bossTargetPos,
        controller: EffectController(
          duration: 0.4,
          curve: Curves.easeOutQuad,
        ),
      ),
    );

    final playerTargetPos = player.logicalPosition - direction * pushDistance;
    player.moveTo(playerTargetPos);

    // ✅【3】嘴臭（根据属性判断 嘲讽 / 暴怒）
    if (boss.tauntCooldown <= 0) {
      boss.tauntCooldown = double.infinity;

      PlayerStorage.getPlayer().then((playerData) {
        if (playerData == null) return;

        final tauntListWeak = [
          "蝼蚁，竟敢靠近？", "你不配！", "找死！", "渺小生灵！", "别自取灭亡！", "这点修为也敢嚣张？",
          "死吧！", "你很吵。", "来送死的吗？", "回去再修个万年吧！", "小东西！", "连看你都觉得浪费时间！",
        ];

        final tauntListAngry = [
          "你竟然伤到我？！", "混账东西！", "你惹怒我了！", "区区人类也敢如此放肆？", "我会撕了你！",
          "好大的狗胆！", "我要让你灰飞烟灭！", "不知死活！！", "我记住你了！", "竟有此等修为？",
        ];

        final playerAtk = PlayerStorage.getAtk(playerData);
        final playerDef = PlayerStorage.getDef(playerData);
        final bossAtk = boss.atk ?? 0;
        final bossDef = boss.def ?? 0;

        final playerPower = playerAtk + playerDef;
        final bossPower = bossAtk + bossDef;

        final isPlayerWeaker = playerPower <= bossPower;

        final tauntList = isPlayerWeaker ? tauntListWeak : tauntListAngry;
        final taunt = tauntList[Random().nextInt(tauntList.length)];

        final tauntPos = boss.logicalPosition - Vector2(0, boss.size.y / 2 + 8);

        boss.parent?.add(FloatingTextComponent(
          text: taunt,
          logicalPosition: tauntPos,
          color: isPlayerWeaker ? Colors.deepOrangeAccent : Colors.redAccent,
        ));

        Future.delayed(const Duration(seconds: 5), () {
          boss.tauntCooldown = 0;
        });
      });
    }
  }
}
