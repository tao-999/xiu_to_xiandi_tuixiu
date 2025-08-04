import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/pill.dart';
import '../../services/collected_pill_storage.dart';
import '../../services/pill_storage_service.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';

class Danyao1CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent danyao,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    final rand = Random();

    if (danyao.isDead || danyao.collisionCooldown > 0) return;
    danyao.collisionCooldown = double.infinity;

    final type = danyao.type;
    late PillType pillType;
    late String iconPath;

    switch (type) {
      case 'danyao_1':
        pillType = PillType.attack;
        iconPath = 'danyao_gongji_1.png';
        break;
      case 'danyao_2':
        pillType = PillType.defense;
        iconPath = 'danyao_fangyu_1.png';
        break;
      case 'danyao_3':
        pillType = PillType.health;
        iconPath = 'danyao_xueliang_1.png';
        break;
      default:
        print('⚠️ 未知丹药类型: $type');
        return;
    }

    final imagePath = iconPath;
    final label = danyao.label?.text ?? '未知丹药';

    // 📏 计算距离 → 等级
    final distance = danyao.logicalPosition.length;
    final level = (log(distance) / log(10) - 5).floor().clamp(1, 999);

    // 🎯 随等级翻倍属性奖励范围
    int bonus;
    switch (pillType) {
      case PillType.attack:
        final minAtk = pow(2, level - 1).toInt();
        final maxAtk = minAtk * 10;
        bonus = rand.nextInt(maxAtk - minAtk + 1) + minAtk;
        break;
      case PillType.defense:
        final minDef = pow(2, level - 1).toInt();
        final maxDef = minDef * 5;
        bonus = rand.nextInt(maxDef - minDef + 1) + minDef;
        break;
      case PillType.health:
        final minHp = pow(2, level - 1).toInt() * 10;
        final maxHp = minHp * 10;
        bonus = rand.nextInt(maxHp - minHp + 1) + minHp;
        break;
    }

    final newPill = Pill(
      name: label,
      level: level,
      type: pillType,
      count: 1,
      bonusAmount: bonus,
      createdAt: DateTime.now(),
      iconPath: imagePath,
    );

    PillStorageService.addPill(newPill);
    CollectedPillStorage.markCollected(danyao.spawnedTileKey);

    final rewardText = '获得 $label ×1';
    final centerPos = danyao.findGame()!.size / 2;

    danyao.findGame()!.camera.viewport.add(FloatingLingShiPopupComponent(
      text: rewardText,
      imagePath: imagePath,
      position: centerPos,
    ));

    danyao.parent?.add(FloatingTextComponent(
      text: rewardText,
      logicalPosition: danyao.logicalPosition - Vector2(0, danyao.size.y / 2 + 8),
      color: Colors.deepOrange,
    ));

    danyao.removeFromParent();
    danyao.isDead = true;
    danyao.label?.removeFromParent();
    danyao.label = null;
    resourceBarKey.currentState?.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      danyao.collisionCooldown = 0;
    });
  }
}
