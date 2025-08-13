// 📄 lib/utils/collision/gongfa1_collision_handler.dart (路径按你项目放)
import 'dart:math';
import 'package:flutter/material.dart';

import '../../data/movement_gongfa_data.dart';
import '../../data/attack_gongfa_data.dart';
import '../../models/gongfa.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../utils/global_distance.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';
import '../../widgets/components/resource_bar.dart';

class Gongfa1CollisionHandler {
  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent gongfaBook,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    final rand = Random();

    // ✅ 冷却
    if (gongfaBook.isDead || gongfaBook.collisionCooldown > 0) return;
    gongfaBook.collisionCooldown = double.infinity;

    // ✅ 按距离决定最高等级 → 随机出最终等级
    final game = gongfaBook.findGame()!;
    final double dist = computeGlobalDistancePx(comp: gongfaBook, game: game);
    final maxLevel = _calculateMaxLevel(dist);
    final selectedLevel = _pickRandomLevel(maxLevel, rand);

    // ✅ 50/50：攻击 or 速度
    final bool dropMovement = rand.nextBool();

    // 每升 1 级 +5%（小数）
    const double kPerLevel = 0.05;

    late Gongfa finalGongfa;
    if (dropMovement) {
      // —— 速度功法 —— //
      final base = MovementGongfaData.all[rand.nextInt(MovementGongfaData.all.length)];
      final double scaledSpeed = base.moveSpeedBoost + (selectedLevel - 1) * kPerLevel;

      finalGongfa = Gongfa(
        id: _newUniqueGongfaId(rand),
        name: base.name,
        level: selectedLevel,
        type: base.type, // GongfaType.movement
        description: base.description,
        atkBoost: 0,
        defBoost: 0,
        hpBoost: 0,
        moveSpeedBoost: scaledSpeed, // 小数
        iconPath: base.iconPath,
        isLearned: false,
        attackSpeed: 1.0,
        acquiredAt: DateTime.now(),
        count: 1,
      );
    } else {
      // —— 攻击功法（火球术）—— //
      final base = AttackGongfaData.all[rand.nextInt(AttackGongfaData.all.length)];
// 每级 +5% → 直接加到倍数上：Lv2=1.10+0.05=1.15
      final double scaledAtk = base.atkBoost + (selectedLevel - 1) * kPerLevel; // 倍数

      finalGongfa = Gongfa(
        id: _newUniqueGongfaId(rand),
        name: base.name, // 火球术
        level: selectedLevel,
        type: base.type, // GongfaType.attack
        description: base.description,
        atkBoost: scaledAtk,     // ✅ 直接存倍数，比如 1.10 / 1.15
        defBoost: 0,
        hpBoost: 0,
        moveSpeedBoost: 0.0,
        iconPath: base.iconPath,
        isLearned: false,
        acquiredAt: DateTime.now(),
        count: 1,
      );

    }

    // ✅ 入库 + 标记已拾取
    GongfaCollectedStorage.addGongfa(finalGongfa);
    GongfaCollectedStorage.markCollected(gongfaBook.spawnedTileKey);

    // ✅ 飘字
    game.add(FloatingIconTextPopupComponent(
      text: '获得功法《${finalGongfa.name}》Lv.$selectedLevel',
      imagePath: finalGongfa.iconPath,
      position: game.size / 2,
    ));

    // ✅ 清理
    gongfaBook.isDead = true;
    gongfaBook.removeFromParent();
    gongfaBook.label?.removeFromParent();
    gongfaBook.label = null;

    // ✅ 延迟重置冷却
    Future.delayed(const Duration(seconds: 2), () {
      gongfaBook.collisionCooldown = 0;
    });
  }

  // —— 工具 —— //
  static int _calculateMaxLevel(double dist) {
    if (dist <= 0) return 1;
    final t = (log(dist) / ln10 + 1e-12).floor(); // 10^t <= dist < 10^(t+1)
    final maxLv = t - 3; // t=4→1；t=5→2；t=6→3 …
    return maxLv < 1 ? 1 : maxLv;
  }

  static int _pickRandomLevel(int maxLevel, Random rand) {
    const double r = 0.7; // 衰减
    final double total = (1 - pow(r, maxLevel)) / (1 - r);
    double roll = rand.nextDouble() * total;
    double w = 1.0;
    for (int k = 1; k <= maxLevel; k++) {
      if (roll < w) return k;
      roll -= w;
      w *= r;
    }
    return maxLevel;
  }

  static String _newUniqueGongfaId(Random rand) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rn = rand.nextInt(1 << 31).toRadixString(16).padLeft(8, '0');
    return 'gf_${ts}_$rn';
  }
}
