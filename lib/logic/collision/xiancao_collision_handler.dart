import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/all_pill_recipes.dart'; // 提供 levelMaterials
import '../../services/collected_xiancao_storage.dart';
import '../../services/herb_material_service.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';

class XiancaoCollisionHandler {
  static final Random _rand = Random();

  /// ✅ 自动生成阶数边界（与 levelMaterials 对齐）
  static final List<int> _levelBounds = _generateLevelBounds();

  static List<int> _generateLevelBounds({
    int start = 10_000,
    int multiplier = 10,
  }) {
    final List<int> bounds = [];
    int value = start;
    for (int i = 0; i < levelMaterials.length; i++) {
      bounds.add(value);
      value *= multiplier;
    }
    return bounds;
  }

  /// ✅ 权重生成（指数衰减，保证最后一阶 ≥ 2%）
  static List<double> _generateNormalizedWeights({
    required int maxLevel,
  }) {
    final base = 1.0 / maxLevel;
    final weights = List<double>.filled(maxLevel, base);

    if (maxLevel <= 1) return weights;

    final half = maxLevel ~/ 2;
    final isOdd = maxLevel % 2 == 1;

    // 低阶：吃补
    final lowIndices = List.generate(half, (i) => i);

    // 高阶：出血（奇数中间阶保留）
    final highStart = isOdd ? half + 1 : half;
    final highIndices = List.generate(maxLevel - highStart, (i) => highStart + i);

    // 高阶每阶让出 50%
    final bleedPer = base * 0.5;
    final totalBleed = bleedPer * highIndices.length;
    final addPer = totalBleed / lowIndices.length;

    for (final hi in highIndices) {
      weights[hi] -= bleedPer;
    }
    for (final li in lowIndices) {
      weights[li] += addPer;
    }

    return weights;
  }

  /// ✅ 权重抽阶（返回 1-based 阶数）
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
    required FloatingIslandDynamicMoverComponent xiancao,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    if (xiancao.isDead || xiancao.collisionCooldown > 0) return;
    xiancao.collisionCooldown = double.infinity;

    final distance = xiancao.logicalPosition.length;

    // ✅ 获取最大阶（根据距离）
    int maxLevel = _levelBounds.indexWhere((b) => distance < b);
    if (maxLevel == -1) {
      maxLevel = levelMaterials.length;
    } else {
      maxLevel += 1;
    }

    // ✅ 生成概率列表 & 抽取阶数
    final probs = _generateNormalizedWeights(maxLevel: maxLevel);
    final selectedLevel = _pickLevelByProbabilities(probs);

    // ✅ 从对应阶中随机一个仙草名
    final materials = levelMaterials[selectedLevel - 1];
    final name = materials[_rand.nextInt(materials.length)];

    // ✅ 保存仙草（每次就1个）
    HerbMaterialService.add(name, 1);

    // ✅ 弹窗提示
    final game = xiancao.findGame();
    if (game != null) {
      final rewardText = '采集到【$name】×1';
      final centerPos = game.size / 2;

      game.camera.viewport.add(FloatingTextComponent(
        text: rewardText,
        logicalPosition: xiancao.logicalPosition - Vector2(0, xiancao.size.y / 2 + 8),
        color: Colors.greenAccent,
      ));

      game.camera.viewport.add(FloatingIconTextPopupComponent(
        text: rewardText,
        imagePath: 'assets/images/herbs/$name.png',
        position: centerPos,
      ));
    }

    // ✅ 标记已采集
    CollectedXiancaoStorage.markCollected(xiancao.spawnedTileKey);

    // ✅ 清理组件 & 刷新
    xiancao.removeFromParent();
    xiancao.isDead = true;
    xiancao.label?.removeFromParent();
    xiancao.label = null;
    resourceBarKey.currentState?.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      xiancao.collisionCooldown = 0;
    });
  }
}
