// 📄 lib/utils/collision/gongfa1_collision_handler.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../../data/movement_gongfa_data.dart';
import '../../data/attack_gongfa_data.dart';
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
    final rand = Random();

    // 冷却/一次性
    if (gongfaBook.isDead || gongfaBook.collisionCooldown > 0) return;
    gongfaBook.collisionCooldown = double.infinity;

    // ✅ 固定掉落 Lv.1
    const int selectedLevel = 1;

    // 50/50：攻击 or 速度
    final bool dropMovement = rand.nextBool();

    late Gongfa finalGongfa;

    if (dropMovement) {
      // —— 速度功法 —— //
      final base = MovementGongfaData.all[rand.nextInt(MovementGongfaData.all.length)];

      finalGongfa = Gongfa(
        id: _newUniqueGongfaId(rand),
        name: base.name,
        level: selectedLevel,            // ← 固定 1
        type: base.type,                 // GongfaType.movement
        description: base.description,
        atkBoost: 0.0,
        defBoost: 0.0,
        hpBoost: 0.0,
        moveSpeedBoost: base.moveSpeedBoost, // 直接用基础值
        iconPath: base.iconPath,
        isLearned: false,
        attackSpeed: 1.0,
        acquiredAt: DateTime.now(),
        count: 1,
      );
    } else {
      // —— 攻击功法 —— //
      final base = AttackGongfaData.all[rand.nextInt(AttackGongfaData.all.length)];

      finalGongfa = Gongfa(
        id: _newUniqueGongfaId(rand),
        name: base.name,
        level: selectedLevel,            // ← 固定 1
        type: base.type,                 // GongfaType.attack
        description: base.description,
        atkBoost: base.atkBoost,         // 直接用基础倍数，如 1.10
        defBoost: 0.0,
        hpBoost: 0.0,
        moveSpeedBoost: 0.0,
        iconPath: base.iconPath,
        isLearned: false,
        acquiredAt: DateTime.now(),
        count: 1,
      );
    }

    // 入库 + 标记已拾取
    GongfaCollectedStorage.addGongfa(finalGongfa);
    GongfaCollectedStorage.markCollected(gongfaBook.spawnedTileKey);

    // 飘字
    final game = gongfaBook.findGame()!;
    game.add(FloatingIconTextPopupComponent(
      text: '获得功法《${finalGongfa.name}》Lv.$selectedLevel',
      imagePath: finalGongfa.iconPath,
      position: game.size / 2,
    ));

    // 清理
    gongfaBook.isDead = true;
    gongfaBook.removeFromParent();
    gongfaBook.label?.removeFromParent();
    gongfaBook.label = null;

    // 冷却恢复
    Future.delayed(const Duration(seconds: 2), () {
      gongfaBook.collisionCooldown = 0;
    });
  }

  // —— 工具 —— //
  static String _newUniqueGongfaId(Random rand) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rn = rand.nextInt(1 << 31).toRadixString(16).padLeft(8, '0');
    return 'gf_${ts}_$rn';
  }
}
