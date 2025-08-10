import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/all_refine_blueprints.dart'; // 提供 levelForgeMaterials
import '../../services/collected_jinkuang_storage.dart';
import '../../services/refine_material_service.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';

class JinkuangCollisionHandler {
  static final Random _rand = Random();

  /// ✅ 阶数边界
  static final List<int> _levelBounds = _generateLevelBounds();

  static List<int> _generateLevelBounds({
    int start = 15_000,
    int multiplier = 10,
  }) {
    final List<int> bounds = [];
    int value = start;
    for (int i = 0; i < levelForgeMaterials.length; i++) {
      bounds.add(value);
      value *= multiplier;
    }
    return bounds;
  }

  /// ✅ 权重生成
  static List<double> _generateNormalizedWeights({
    required int maxLevel,
  }) {
    final base = 1.0 / maxLevel;
    final weights = List<double>.filled(maxLevel, base);

    if (maxLevel <= 1) return weights;

    final half = maxLevel ~/ 2;
    final isOdd = maxLevel % 2 == 1;

    final lowIndices = List.generate(half, (i) => i); // 低位索引 0 ~ half-1
    final highStart = isOdd ? half + 1 : half;
    final highIndices = List.generate(maxLevel - highStart, (i) => highStart + i); // 高位索引

    // 总出血量
    final bleedPer = base * 0.5;
    final totalBleed = bleedPer * highIndices.length;

    final addPer = totalBleed / lowIndices.length;

    // 出血
    for (final hi in highIndices) {
      weights[hi] -= bleedPer;
    }

    // 补偿
    for (final li in lowIndices) {
      weights[li] += addPer;
    }

    return weights;
  }

  /// ✅ 权重抽阶（1-based）
  static int _pickLevelByProbabilities(List<double> probabilities) {
    final roll = _rand.nextDouble();
    double sum = 0;
    for (int i = 0; i < probabilities.length; i++) {
      sum += probabilities[i];
      if (roll < sum) return i + 1;
    }
    return probabilities.length;
  }

  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent jinkuang,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    if (jinkuang.isDead || jinkuang.collisionCooldown > 0) return;
    jinkuang.collisionCooldown = double.infinity;

    final distance = jinkuang.logicalPosition.length;

    // ✅ 最大阶（根据距离）
    int maxLevel = _levelBounds.indexWhere((b) => distance < b);
    if (maxLevel == -1) {
      maxLevel = levelForgeMaterials.length;
    } else {
      maxLevel += 1;
    }

    // ✅ 抽阶
    final probs = _generateNormalizedWeights(maxLevel: maxLevel);
    final selectedLevel = _pickLevelByProbabilities(probs);

    // ✅ 从对应阶中抽材料
    final materials = levelForgeMaterials[selectedLevel - 1];
    final name = materials[_rand.nextInt(materials.length)];

    // ✅ 存储材料
    RefineMaterialService.add(name, 1);

    // ✅ 弹窗提示
    final game = jinkuang.findGame();
    if (game != null) {
      final rewardText = '开采到【$name】×1';
      final centerPos = game.size / 2;

      game.camera.viewport.add(FloatingTextComponent(
        text: rewardText,
        logicalPosition: jinkuang.logicalPosition - Vector2(0, jinkuang.size.y / 2 + 8),
        color: Colors.amberAccent,
      ));

      game.camera.viewport.add(FloatingIconTextPopupComponent(
        text: rewardText,
        imagePath: 'assets/images/materials/$name.png',
        position: centerPos,
      ));
    }

    // ✅ 标记已采集
    CollectedJinkuangStorage.markCollected(jinkuang.spawnedTileKey);

    // ✅ 清理 & 刷新
    jinkuang.removeFromParent();
    jinkuang.isDead = true;
    jinkuang.label?.removeFromParent();
    jinkuang.label = null;
    resourceBarKey.currentState?.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      jinkuang.collisionCooldown = 0;
    });
  }
}
