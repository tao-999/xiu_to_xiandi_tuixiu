import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/constants/aptitude_table.dart';

/// 🌌 修仙设定常量
class CultivationConfig {
  static const int levelsPerRealm = 10;

  /// ✅ 由 aptitudeTable 生成境界名列表
  static List<String> get realms => aptitudeTable.map((e) => e.realmName).toList();

  static int get maxLevel => realms.length * levelsPerRealm;

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

/// 🎨 用于 UI 显示的修为进度
class CultivationLevelDisplay {
  final String realm;
  final int rank;
  final BigInt current;
  final BigInt max;

  CultivationLevelDisplay(this.realm, this.rank, this.current, this.max);
}

/// 🧮 当前修为对应的境界状态（逻辑用）
class CultivationLevel {
  final String realm;
  final int rank;
  final double progress;     // 当前层内进度百分比（用于 UI）
  final BigInt totalExp;     // 当前层所需经验
  final int totalLayer;      // 第几层（全局）
  final BigInt levelStart;   // 当前层起点经验（用于计算 current）

  CultivationLevel(
      this.realm,
      this.rank,
      this.progress,
      this.totalExp,
      this.totalLayer,
      this.levelStart,
      );
}

/// 🔢 单层所需修为（线性增长）
BigInt expNeededForLevel(int level) {
  if (level <= 1) return BigInt.from(1000);

  BigInt base = BigInt.from(1000);
  int segment = (level - 1) ~/ 10;
  int offset = (level - 1) % 10;

  for (int i = 0; i < segment; i++) {
    final BigInt delta = base ~/ BigInt.two;
    final BigInt lastLayer = base + delta * BigInt.from(9); // 第10层
    base = lastLayer * BigInt.two; // 下一段的base
  }

  final BigInt delta = base ~/ BigInt.two;
  return base + delta * BigInt.from(offset);
}

/// 📈 累计修为总值（起点经验）
BigInt totalExpToLevel(int level) {
  BigInt total = BigInt.zero;
  for (int i = 1; i < level; i++) {
    total += expNeededForLevel(i);
  }
  return total;
}

/// 🧠 根据当前修为，计算所属境界层数 + 进度（BigInt版）
CultivationLevel calculateCultivationLevel(BigInt cultivationExp) {
  final int totalLevels = CultivationConfig.maxLevel;

  for (int level = 1; level <= totalLevels; level++) {
    final BigInt start = totalExpToLevel(level);
    final BigInt amount = expNeededForLevel(level);
    final BigInt end = start + amount;

    if (cultivationExp <= end) {
      final int realmIndex = (level - 1) ~/ CultivationConfig.levelsPerRealm;
      final int rank = (level - 1) % CultivationConfig.levelsPerRealm + 1;
      final realm = CultivationConfig.realms[realmIndex];
      final progress = (cultivationExp - start).toDouble() / amount.toDouble();

      return CultivationLevel(
        realm,
        rank,
        progress,
        amount,
        level,
        start,
      );
    }
  }

  // ✅ 修为已达最大层（等于或超过 maxLevel 的终点）
  final int maxLevel = totalLevels;
  final BigInt start = totalExpToLevel(maxLevel);
  final BigInt amount = expNeededForLevel(maxLevel);
  final realm = CultivationConfig.realms.last;

  return CultivationLevel(
    realm,
    10,
    1.0,
    amount,
    maxLevel,
    start,
  );
}

/// 🎯 获取 SharedPreferences 中的修为数据并转换为 UI 进度
Future<CultivationLevelDisplay> getDisplayLevelFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('playerData') ?? '{}';
  final json = jsonDecode(raw);

  final BigInt cultivationExp = BigInt.tryParse(json['cultivation'].toString()) ?? BigInt.zero;

  // 🌱 直接读取资质
  final int aptitude = json['aptitude'] ?? 0;

  // 🌌 资质对应的最大修炼层数（如果你有其他规则可在这里调整）
  final int maxLevel = aptitude;

  // ⛳ 允许的最大修为值（到 maxLevel 层结束为止）
  final BigInt maxAllowedExp = totalExpToLevel(maxLevel + 1);

  // ✅ 封顶逻辑：允许修满当前层，但不能进入下一层
  final BigInt cappedExp = cultivationExp > maxAllowedExp
      ? maxAllowedExp
      : cultivationExp;

  // 🧮 计算当前所属层级信息
  final info = calculateCultivationLevel(cappedExp);
  final BigInt current = cappedExp - info.levelStart;
  final bool isFull = current >= info.totalExp;

  return CultivationLevelDisplay(
    info.realm,
    info.rank,
    isFull ? info.totalExp : current,
    info.totalExp,
  );
}


