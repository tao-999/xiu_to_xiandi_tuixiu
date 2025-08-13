// 📂 lib/widgets/components/handlers/favorability_collision_handler.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/favorability_data.dart';
import '../../services/collected_favorability_storage.dart';
import '../../services/favorability_material_service.dart';
import '../../utils/global_distance.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';

class FavorabilityCollisionHandler {
  static final Random _rand = Random();

  /// ✅ 阶数边界（与 FavorabilityData.items 长度对齐）
  static final List<int> _levelBounds = _generateLevelBounds();

  static List<int> _generateLevelBounds({
    int start = 10_000,
    int multiplier = 10,
  }) {
    final List<int> bounds = [];
    int value = start;
    for (int i = 0; i < FavorabilityData.items.length; i++) {
      bounds.add(value);
      value *= multiplier;
    }
    return bounds;
  }

  static List<double> _generateNormalizedWeights({
    required int maxLevel,
  }) {
    final base = 1.0 / maxLevel;
    final weights = List<double>.filled(maxLevel, base);

    if (maxLevel <= 1) return weights;

    final half = maxLevel ~/ 2;
    final isOdd = maxLevel % 2 == 1;

    final lowIndices = List.generate(half, (i) => i); // 低阶索引
    final highStart = isOdd ? half + 1 : half;
    final highIndices = List.generate(maxLevel - highStart, (i) => highStart + i); // 高阶索引

    // 高阶每阶让出 base * 0.5
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
    required FloatingIslandDynamicMoverComponent favorItem,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    if (favorItem.isDead || favorItem.collisionCooldown > 0) return;
    favorItem.collisionCooldown = double.infinity;

    final game = favorItem.findGame()!;
    final double distance = computeGlobalDistancePx(comp: favorItem, game: game);

    // ✅ 获取最大阶（根据距离）
    int maxLevel = _levelBounds.indexWhere((b) => distance < b);
    if (maxLevel == -1) {
      maxLevel = FavorabilityData.items.length;
    } else {
      maxLevel += 1;
    }

    // ✅ 生成概率列表 & 抽取阶数
    final probs = _generateNormalizedWeights(maxLevel: maxLevel);
    final selectedLevel = _pickLevelByProbabilities(probs);

    // ✅ 获取材料索引（1-based）
    final materialIndex = selectedLevel;

    // ✅ 保存材料
    FavorabilityMaterialService.addMaterial(materialIndex, 1);

    // ✅ 弹窗提示
    if (game != null) {
      final favorItemData = FavorabilityData.getByIndex(materialIndex);
      final rewardText = '获得【${favorItemData.name}】×1';
      final centerPos = game.size / 2;

      game.camera.viewport.add(FloatingTextComponent(
        text: rewardText,
        logicalPosition: favorItem.logicalPosition - Vector2(0, favorItem.size.y / 2 + 8),
        color: Colors.pinkAccent,
      ));

      game.camera.viewport.add(FloatingIconTextPopupComponent(
        text: rewardText,
        imagePath: favorItemData.assetPath,
        position: centerPos,
      ));
    }

    // ✅ 标记已采集
    CollectedFavorabilityStorage.markCollected(favorItem.spawnedTileKey);

    // ✅ 清理组件 & 刷新
    favorItem.removeFromParent();
    favorItem.isDead = true;
    favorItem.label?.removeFromParent();
    favorItem.label = null;
    resourceBarKey.currentState?.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      favorItem.collisionCooldown = 0;
    });
  }
}
