import 'dart:math';
import 'package:flutter/material.dart';

import '../../data/movement_gongfa_data.dart';
import '../../models/gongfa.dart';
import '../../services/gongfa_collected_storage.dart';
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
    print('📜 [Gongfa1] 玩家拾取功法 → pos=${player.logicalPosition}');
    print('⏳ collisionCooldown = ${gongfaBook.collisionCooldown.toStringAsFixed(2)} 秒');

    final rand = Random();

    // ✅ 冷却
    if (gongfaBook.isDead || gongfaBook.collisionCooldown > 0) return;
    gongfaBook.collisionCooldown = double.infinity;

    // ✅ 按距离决定最高等级 → 随机出最终等级
    final dist = gongfaBook.logicalPosition.length;
    final maxLevel = _calculateMaxLevel(dist);
    final selectedLevel = _pickRandomLevel(maxLevel, rand);

    // ✅ 从“速度功法池”抽一本模板（只取名字/描述/图标/基础数值，不用它的 id）
    final all = MovementGongfaData.all;
    final base = all[rand.nextInt(all.length)];

    // 每升 1 级 +5%（用小数表示）
    const double kSpeedPerLevel = 0.05;

// 基础模板(小数) + 等级增量(小数)
    final double scaledSpeed =
        base.moveSpeedBoost + (selectedLevel - 1) * kSpeedPerLevel;

    // ✅ 生成全新唯一 id（确保与仓库的“同 id+level 合并”规则不冲突）
    final newId = _newUniqueGongfaId(rand);

    final finalGongfa = Gongfa(
      id: newId, // 🔥 用全新 id
      name: base.name,
      level: selectedLevel,
      type: base.type, // movement
      description: base.description,
      atkBoost: 0,
      defBoost: 0,
      hpBoost: 0,
      moveSpeedBoost: scaledSpeed,
      iconPath: base.iconPath,
      isLearned: false,
      acquiredAt: DateTime.now(),
      count: 1, // 🔒 每一本都是唯一实例，数量固定为 1
    );

    // ✅ 入库 + 标记已拾取
    GongfaCollectedStorage.addGongfa(finalGongfa);
    GongfaCollectedStorage.markCollected(gongfaBook.spawnedTileKey);

    // ✅ 飘字
    final rewardText = '获得功法《${base.name}》Lv.$selectedLevel';
    final game = gongfaBook.findGame()!;
    final centerPos = game.size / 2;
    game.add(FloatingIconTextPopupComponent(
      text: rewardText,
      imagePath: base.iconPath,
      position: centerPos,
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

  // ===== 工具 =====

  // 距离 → 最大等级：<1e5 只能 Lv1；<1e6 可 1~2；<1e7 可 1~3 …
  static int _calculateMaxLevel(double dist) {
    if (dist <= 0) return 1;
    final t = (log(dist) / ln10 + 1e-12).floor(); // 10^t <= dist < 10^(t+1)
    final maxLv = t - 3; // t=4→1；t=5→2；t=6→3…
    return maxLv < 1 ? 1 : maxLv; // 不设上限，只保底
  }

  // 递减概率：P(L=k) ∝ r^(k-1)
  static int _pickRandomLevel(int maxLevel, Random rand) {
    const double r = 0.7;
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

  // 生成唯一功法 id（时间戳 + 随机）
  static String _newUniqueGongfaId(Random rand) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rn = rand.nextInt(1 << 31).toRadixString(16).padLeft(8, '0');
    return 'gf_${ts}_$rn';
  }
}

extension LogExtension on num {
  double log10() => log(this) / ln10;
}
