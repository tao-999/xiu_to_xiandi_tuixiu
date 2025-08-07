import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/gongfa_data.dart';
import '../../models/gongfa.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_lingshi_popup_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';

class Gongfa1CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent gongfaBook,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    print('📜 [Gongfa1] 玩家拾取功法 → pos=${player.logicalPosition}');
    print('⏳ collisionCooldown = ${gongfaBook.collisionCooldown.toStringAsFixed(2)} 秒');

    final rand = Random();

    // ✅ 加上 cooldown 判断，和丹药一致
    if (gongfaBook.isDead || gongfaBook.collisionCooldown > 0) return;
    gongfaBook.collisionCooldown = double.infinity;

    final dist = gongfaBook.logicalPosition.length;
    final maxLevel = _calculateMaxLevel(dist);
    final selectedLevel = _pickRandomLevel(maxLevel, rand);

    final all = GongfaData.all;
    final base = all[rand.nextInt(all.length)];

    final finalGongfa = Gongfa(
      id: base.id,
      name: base.name,
      level: selectedLevel,
      type: base.type,
      description: base.description,
      atkBoost: base.atkBoost * pow(2, selectedLevel - 1).toInt(),
      defBoost: base.defBoost * pow(2, selectedLevel - 1).toInt(),
      hpBoost: base.hpBoost * pow(2, selectedLevel - 1).toInt(),
      iconPath: base.iconPath,
      isLearned: false,
      acquiredAt: DateTime.now(),
      count: 1,
    );

    GongfaCollectedStorage.addGongfa(finalGongfa);
    GongfaCollectedStorage.markCollected(gongfaBook.spawnedTileKey);

    final rewardText = '获得功法《${base.name}》Lv.$selectedLevel';
    final game = gongfaBook.findGame()!;
    final centerPos = game.size / 2;

    game.add(FloatingLingShiPopupComponent(
      text: rewardText,
      imagePath: base.iconPath,
      position: centerPos,
    ));

    // ✅ 死亡标记
    gongfaBook.isDead = true;
    gongfaBook.removeFromParent();
    gongfaBook.label?.removeFromParent();
    gongfaBook.label = null;

    // ✅ 延迟重置 cooldown（防止短时间重复激活）
    Future.delayed(const Duration(seconds: 2), () {
      gongfaBook.collisionCooldown = 0;
    });
  }

  static int _calculateMaxLevel(double dist) {
    if (dist < 1) return 1;
    return dist.log10().floor() + 1;
  }

  static int _pickRandomLevel(int maxLevel, Random rand) {
    for (int level = maxLevel; level >= 1; level--) {
      final chance = 1 / pow(2, level - 1);
      if (rand.nextDouble() < chance) return level;
    }
    return 1;
  }
}

extension LogExtension on num {
  double log10() => log(this) / ln10;
}
