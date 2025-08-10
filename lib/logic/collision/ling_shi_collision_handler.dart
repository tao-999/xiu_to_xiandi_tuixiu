import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/collected_lingshi_storage.dart';
import '../../services/resources_storage.dart';
import '../../utils/lingshi_util.dart';
import '../../utils/number_format.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_icon_text_popup_component.dart';
import '../../widgets/components/floating_text_component.dart';
import '../../widgets/components/resource_bar.dart';

class LingShiCollisionHandler {
  static final Random _rand = Random();

  static const List<int> _levelBounds = [
    100000,        // 10 万 → 解锁中品
    10000000,      // 1000 万 → 解锁上品
    1000000000,    // 10 亿 → 解锁极品
  ];

  static const Map<LingShiType, int> _divisorMap = {
    LingShiType.lower: 1,
    LingShiType.middle: 1000,
    LingShiType.upper: 1000000,
    LingShiType.supreme: 1000000000,
  };

  static List<double> _generateNormalizedWeights({
    required int maxLevel,
    double decayPower = 1.5,
    double minLastPercent = 0.02,
  }) {
    final weights = List<double>.generate(
      maxLevel,
          (i) => 1.0 / pow(i + 1, decayPower),
    );

    final rawTotal = weights.reduce((a, b) => a + b);
    final lastRatio = weights.last / rawTotal;

    if (lastRatio < minLastPercent) {
      final boost = minLastPercent * rawTotal - weights.last;
      weights[weights.length - 1] += boost;
    }

    final total = weights.reduce((a, b) => a + b);
    return weights.map((w) => w / total).toList();
  }

  static int _pickLevelByProbabilities(List<double> probabilities) {
    final roll = _rand.nextDouble();
    double sum = 0;
    for (int i = 0; i < probabilities.length; i++) {
      sum += probabilities[i];
      if (roll < sum) return i;
    }
    return probabilities.length - 1;
  }

  static void handle({
    required FloatingIslandPlayerComponent player,
    required FloatingIslandDynamicMoverComponent lingShi,
    required GlobalKey<ResourceBarState> resourceBarKey,
  }) {
    if (lingShi.isDead || lingShi.collisionCooldown > 0) return;
    lingShi.collisionCooldown = double.infinity;

    final distance = lingShi.logicalPosition.length;

    // ✅ 计算最大可抽阶数（最多为 4）
    int maxLevel = _levelBounds.indexWhere((b) => distance < b);
    if (maxLevel == -1) {
      maxLevel = 4;
    } else {
      maxLevel += 1;
    }

    // ✅ 抽取灵石阶数
    final probs = _generateNormalizedWeights(maxLevel: maxLevel);
    final selectedIndex = _pickLevelByProbabilities(probs);
    final type = LingShiType.values[selectedIndex];

    // ✅ 掉落数量：距离 ÷ 阶数倍率 × (0.01 ~ 0.1)
    final int divisor = _divisorMap[type]!;
    final int adjustedDistance = (distance ~/ divisor);
    final double ratio = _rand.nextDouble() * 0.09 + 0.01; // 0.01 ~ 0.1
    final int count = max(1, (adjustedDistance * ratio).floor());

    // ✅ 增加资源
    final fieldName = lingShiFieldMap[type]!;
    ResourcesStorage.add(fieldName, BigInt.from(count));

    // ✅ 弹窗与飘字
    final game = lingShi.findGame();
    if (game != null) {
      final formattedCount = formatAnyNumber(count);
      final rewardText = '获得【${lingShiNames[type]}】×$formattedCount';
      final centerPos = game.size / 2;

      game.camera.viewport.add(FloatingTextComponent(
        text: rewardText,
        logicalPosition: lingShi.logicalPosition - Vector2(0, lingShi.size.y / 2 + 8),
        color: Colors.amberAccent,
      ));

      game.camera.viewport.add(FloatingIconTextPopupComponent(
        text: rewardText,
        imagePath: getLingShiImagePath(type),
        position: centerPos,
      ));
    }
    CollectedLingShiStorage.markCollected(lingShi.spawnedTileKey);

    // ✅ 清理组件 & 刷新资源条
    lingShi.removeFromParent();
    lingShi.isDead = true;
    lingShi.label?.removeFromParent();
    lingShi.label = null;
    resourceBarKey.currentState?.refresh();

    Future.delayed(const Duration(seconds: 2), () {
      lingShi.collisionCooldown = 0;
    });
  }
}
