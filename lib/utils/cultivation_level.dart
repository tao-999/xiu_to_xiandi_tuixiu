import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

/// 🌌 修仙设定常量
class CultivationConfig {
  static const double baseExp = 100.0;
  static const double expMultiplier = 1.3;
  static const int levelsPerRealm = 10;

  static const List<String> realms = [
    "练气期",
    "筑基期",
    "金丹期",
    "元婴期",
    "化神期",
    "炼虚期",
    "合体期",
    "大乘期",
    "渡劫期",
    "飞升",
  ];

  static int get maxLevel => realms.length * levelsPerRealm;
}

/// 🧮 当前修为对应的境界状态（逻辑用）
class CultivationLevel {
  final String realm;
  final int rank;        // 当前大境界内的层数（第几重）
  final double progress; // 当前层内进度 0~1
  final double totalExp; // 当前层所需修为

  CultivationLevel(this.realm, this.rank, this.progress, this.totalExp);

  int get totalLayer => CultivationConfig.realms.indexOf(realm) * CultivationConfig.levelsPerRealm + rank;

  @override
  String toString() {
    return '$realm 第 $rank 重（${(progress * 100).toStringAsFixed(1)}%）';
  }
}

/// 🎨 用于 UI 显示的修为进度
class CultivationLevelDisplay {
  final String realm;
  final int rank;
  final double current;
  final double max;

  CultivationLevelDisplay(this.realm, this.rank, this.current, this.max);
}

/// 🔢 单层所需修为（指数增长）
double expNeededForLevel(int level) {
  return CultivationConfig.baseExp * pow(CultivationConfig.expMultiplier, level - 1);
}

/// 📈 累计修为总值（1 ~ 当前level前一层）
double totalExpToLevel(int level) {
  double total = 0;
  for (int i = 1; i < level; i++) {
    total += expNeededForLevel(i);
  }
  return total;
}

/// 🧮 根据修为数值计算对应的层级与进度
CultivationLevel calculateCultivationLevel(double cultivationExp) {
  int level = 1;
  double accumulatedExp = 0;

  while (level <= CultivationConfig.maxLevel) {
    final currentExp = expNeededForLevel(level);
    final maxThisLevel = accumulatedExp + currentExp;

    if (cultivationExp <= maxThisLevel) break;

    accumulatedExp = maxThisLevel;
    level++;
  }

  final currentLevelExp = expNeededForLevel(level);
  final progress = ((cultivationExp - accumulatedExp) / currentLevelExp).clamp(0.0, 1.0);

  final realmIndex = (level - 1) ~/ CultivationConfig.levelsPerRealm;
  final rank = (level - 1) % CultivationConfig.levelsPerRealm + 1;

  return CultivationLevel(
    CultivationConfig.realms[realmIndex],
    rank,
    progress,
    currentLevelExp,
  );
}

/// 🎯 获取 SharedPreferences 中的修为数据并转换为 UI 进度
Future<CultivationLevelDisplay> getDisplayLevelFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('playerData') ?? '{}';
  final json = jsonDecode(raw);

  final double cultivationExp = (json['cultivation'] ?? 0.0).toDouble();
  final Map<String, dynamic> elements = (json['elements'] ?? {}) as Map<String, dynamic>;
  final int totalElement = elements.values.fold(0, (a, b) => a + (b as int));

  final maxPossibleLevel = CultivationConfig.realms.length * CultivationConfig.levelsPerRealm;
  final maxLevel = (totalElement * 0.9).floor().clamp(1, maxPossibleLevel);

  final levelExpCap = totalExpToLevel(maxLevel + 1); // 取下一级的开始作为边界
  if (cultivationExp >= levelExpCap) {
    final realmIndex = (maxLevel - 1) ~/ CultivationConfig.levelsPerRealm;
    final rank = (maxLevel - 1) % CultivationConfig.levelsPerRealm + 1;
    final levelExp = expNeededForLevel(maxLevel);
    return CultivationLevelDisplay(
      CultivationConfig.realms[realmIndex],
      rank,
      levelExp,
      levelExp,
    );
  }

  final level = calculateCultivationLevel(cultivationExp);
  final justBreakthrough = level.progress == 0.0;

  return CultivationLevelDisplay(
    level.realm,
    level.rank,
    justBreakthrough ? 0.0 : level.progress * level.totalExp,
    level.totalExp,
  );
}
