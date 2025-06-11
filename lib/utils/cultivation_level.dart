import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/player_storage.dart';
import '../widgets/constants/aptitude_table.dart';

/// 🌌 修仙设定常量
class CultivationConfig {
  static const double baseExp = 100.0;
  static const double expMultiplier = 1.3;
  static const int levelsPerRealm = 10;

  /// ✅ 改为动态读取，不再写死
  static List<String> get realms => aptitudeTable.map((e) => e.realmName).toList();

  static int get maxLevel => realms.length * levelsPerRealm;

  /// 根据资质返回最大修炼层数
  static int getMaxLevelByAptitude(int aptitude) {
    final index = aptitudeTable.lastIndexWhere((e) => aptitude >= e.minAptitude);
    return (index + 1) * levelsPerRealm;
  }

  /// 根据资质返回当前最高境界名
  static String getRealmNameByAptitude(int aptitude) {
    for (int i = aptitudeTable.length - 1; i >= 0; i--) {
      if (aptitude >= aptitudeTable[i].minAptitude) {
        return aptitudeTable[i].realmName;
      }
    }
    return aptitudeTable.first.realmName;
  }
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

/// 🔐 浮点容差判断，避免卡在刚好升级边缘
bool isLessWithEpsilon(double a, double b, [double epsilon = 0.0001]) {
  return a < b && (b - a).abs() > epsilon;
}

/// 🧠 根据当前修为，计算所属境界层数 + 进度（无限制版本）
CultivationLevel calculateCultivationLevel(double cultivationExp) {
  // 直接把 ε 写在这儿，别再单独封装了
  const double epsilon = 1e-8;

  int level = 1;
  double accumulatedExp = 0;

  while (true) {
    final needExp = expNeededForLevel(level);
    final threshold = accumulatedExp + needExp;

    // 如果经验 < 阈值 + ε，就认定到这一层，停
    if (cultivationExp < threshold + epsilon) {
      break;
    }

    accumulatedExp = threshold;
    level++;
  }

  final currentLevelExp = expNeededForLevel(level);

  // 如果经验 ≥ 阈值 + ε，就满进度；否则正常计算进度
  final double progress = (cultivationExp >= accumulatedExp + currentLevelExp - epsilon)
      ? 1.0
      : ((cultivationExp - accumulatedExp) / currentLevelExp).clamp(0.0, 1.0);

  final int realmIndex = (level - 1) ~/ CultivationConfig.levelsPerRealm;
  final int rank = (level - 1) % CultivationConfig.levelsPerRealm + 1;

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
  final Map<String, dynamic> rawElements = json['elements'] ?? {};
  final Map<String, int> elements = rawElements.map((k, v) => MapEntry(k, (v as num).toInt())); // ✅ 转换为 Map<String, int>

  final int aptitude = PlayerStorage.calculateTotalElement(elements);

  final int maxLevel = CultivationConfig.getMaxLevelByAptitude(aptitude);
  final levelExpCap = totalExpToLevel(maxLevel + 1);

  if (cultivationExp > levelExpCap) {
    final realmIndex = (maxLevel) ~/ CultivationConfig.levelsPerRealm;
    final rank = (maxLevel) % CultivationConfig.levelsPerRealm + 1;
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
