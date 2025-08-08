import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/pill.dart';
import '../../services/collected_pill_storage.dart';
import '../../services/pill_storage_service.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
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

    // 🎲 随机选择丹药（name, type, iconPath）
    final pillOptions = [
      ('赤焰破虚丹', PillType.attack, 'danyao_gongji_1.png'),
      ('玄晶护体丹', PillType.defense, 'danyao_fangyu_1.png'),
      ('碧魂续命丹', PillType.health, 'danyao_xueliang_1.png'),
    ];
    final selected = pillOptions[rand.nextInt(pillOptions.length)];
    final name = selected.$1;
    final pillType = selected.$2;
    final iconPath = selected.$3;

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

    // 💊 创建丹药对象
    final newPill = Pill(
      name: name,
      level: level,
      type: pillType,
      count: 1,
      bonusAmount: bonus,
      createdAt: DateTime.now(),
      iconPath: iconPath,
    );

    PillStorageService.addPill(newPill);
    CollectedPillStorage.markCollected(danyao.spawnedTileKey);

    final rewardText = '获得 $name ×1';
    final centerPos = danyao.findGame()!.size / 2;

    danyao.findGame()!.camera.viewport.add(FloatingLingShiPopupComponent(
      text: rewardText,
      imagePath: iconPath,
      position: centerPos,
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
