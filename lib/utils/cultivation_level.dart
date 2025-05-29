import 'dart:math';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

/// 🌱 表示修炼者当前的境界状态（用于逻辑判断）
class CultivationLevel {
  final String realm;        // 境界名（如“筑基期”）
  final int rank;            // 第几重（1~9）
  final double progress;     // 当前层内进度 0~1
  final double totalExp;     // 当前层所需修为

  CultivationLevel(this.realm, this.rank, this.progress, this.totalExp);

  /// 🧮 当前总层数（练气1~9 为 1~9，筑基1~9 为 10~18，依此类推）
  int get totalLayer => realms.indexOf(realm) * levelsPerRealm + rank;

  @override
  String toString() {
    return '$realm 第 $rank 重（${(progress * 100).toStringAsFixed(1)}%）';
  }
}

/// 🎨 表示用于 UI 显示的进度信息
class CultivationLevelDisplay {
  final String realm;
  final int rank;
  final double current; // 当前进度值（用于进度条）
  final double max;     // 当前层最大修为值

  CultivationLevelDisplay(this.realm, this.rank, this.current, this.max);
}

// 🌌 所有大境界名称（按顺序排列）
const List<String> realms = [
  "练气期",
  "筑基期",
  "金丹期",
  "元婴期",
  "化神期",
  "炼虚期",
  "合体期",
  "大乘期",
  "渡劫期",
];

const double baseExp = 100.0;      // 第一层所需修为
const double expMultiplier = 1.5;  // 每层增长倍数
const int levelsPerRealm = 9;

/// 📊 每一层所需修为
double expNeededForLevel(int level) {
  return baseExp * pow(expMultiplier, level - 1);
}

/// 🧮 当前层之前所需的累计总修为（用于计算进度）
double totalExpToLevel(int level) {
  double total = 0;
  for (int i = 1; i < level; i++) {
    total += expNeededForLevel(i);
  }
  return total;
}

/// 🔍 根据当前修为返回所在的境界 + 重数 + 当前进度
/// ✅ 满经验不进阶，只有“超出”才代表突破
CultivationLevel calculateCultivationLevel(double cultivationExp) {
  int level = 1;
  double accumulatedExp = 0;

  while (level < 189) {
    final currentExp = expNeededForLevel(level);
    final maxThisLevel = accumulatedExp + currentExp;

    // 如果修为没超过当前层最大修为，就停在这层
    if (cultivationExp < maxThisLevel) break;

    accumulatedExp = maxThisLevel;
    level++;
  }

  final currentLevelExp = expNeededForLevel(level);
  final progress = ((cultivationExp - accumulatedExp) / currentLevelExp).clamp(0.0, 1.0);

  final realmIndex = (level - 1) ~/ levelsPerRealm;
  final rank = (level - 1) % levelsPerRealm + 1;

  return CultivationLevel(
    realms[realmIndex],
    rank,
    progress,
    currentLevelExp,
  );
}

/// 🎯 返回用于 UI 展示的进度信息（突破后自动归零）
CultivationLevelDisplay getDisplayLevel(double cultivationExp, [int? totalElement]) {
  if (totalElement != null) {
    final maxExp = CultivationTracker.getMaxExpByAptitude(totalElement);

    if (cultivationExp >= maxExp) {
      final maxLevel = (totalElement * 0.9).floor().clamp(1, 189);
      final realmIndex = (maxLevel - 1) ~/ levelsPerRealm;
      final rank = (maxLevel - 1) % levelsPerRealm + 1;
      final levelExp = expNeededForLevel(maxLevel);

      return CultivationLevelDisplay(
        realms[realmIndex],
        rank,
        levelExp,
        levelExp,
      );
    }
  }

  final level = calculateCultivationLevel(cultivationExp);

  return CultivationLevelDisplay(
    level.realm,
    level.rank,
    level.progress * level.totalExp,
    level.totalExp,
  );
}
