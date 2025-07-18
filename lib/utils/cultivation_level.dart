import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/constants/aptitude_table.dart';

/// 🌌 修仙设定常量
class CultivationConfig {
  static const int levelsPerRealm = 10;

  /// ✅ 由 aptitudeTable 生成境界名列表
  static List<String> get realms => aptitudeTable.map((e) => e.realmName).toList();

  /// 🚫 不再由资质限制修为等级，统一设定为 220 层
  static int get maxLevel => 220;
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
  final double progress;
  final BigInt totalExp;
  final int totalLayer;
  final BigInt levelStart;

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
/// 0层表示“凡人 → 练气1”，特殊处理
BigInt expNeededForLevel(int level) {
  if (level == 0) return BigInt.from(500); // 🌱 凡人阶段
  if (level == 1) return BigInt.from(1000);

  BigInt base = BigInt.from(1000);
  int segment = (level - 1) ~/ 10;
  int offset = (level - 1) % 10;

  for (int i = 0; i < segment; i++) {
    final BigInt delta = base ~/ BigInt.two;
    final BigInt lastLayer = base + delta * BigInt.from(9);
    base = lastLayer * BigInt.two;
  }

  final BigInt delta = base ~/ BigInt.two;
  return base + delta * BigInt.from(offset);
}

/// 📈 累计修为总值（起点经验）
/// 🧙 从凡人0层起始
BigInt totalExpToLevel(int level) {
  BigInt total = BigInt.zero;
  for (int i = 0; i < level; i++) {
    total += expNeededForLevel(i);
  }
  return total;
}

/// 🧠 根据当前修为，计算所属境界层数 + 进度（BigInt版）
CultivationLevel calculateCultivationLevel(BigInt cultivationExp) {
  final int totalLevels = CultivationConfig.maxLevel;
  final BigInt maxAllowed = totalExpToLevel(totalLevels); // 封顶经验值

  // ✅ 封顶修为，强制固定为 maxLevel 层起点
  if (cultivationExp >= maxAllowed) {
    final realmIndex = (CultivationConfig.maxLevel - 1) ~/ CultivationConfig.levelsPerRealm;
    final String realm = CultivationConfig.realms[realmIndex];

    return CultivationLevel(
      realm,
      CultivationConfig.levelsPerRealm, // rank = 10
      0.0,
      BigInt.zero,
      totalLevels,
      maxAllowed,
    );
  }

  // ✅ 正常遍历
  for (int level = 0; level < totalLevels; level++) {
    final BigInt start = totalExpToLevel(level);
    final BigInt amount = expNeededForLevel(level);
    final BigInt end = start + amount;

    if (cultivationExp < end) {
      final String realm;
      final int rank;

      if (level == 0) {
        realm = '凡人';
        rank = 0;
      } else {
        final realmIndex = (level - 1) ~/ CultivationConfig.levelsPerRealm;
        realm = CultivationConfig.realms[realmIndex];
        rank = (level - 1) % CultivationConfig.levelsPerRealm + 1;
      }

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

  // 🧼 理论不会到这里，但兜底
  return CultivationLevel(
    CultivationConfig.realms.last,
    CultivationConfig.levelsPerRealm,
    0.0,
    BigInt.zero,
    totalLevels,
    maxAllowed,
  );
}

/// 🎯 获取 SharedPreferences 中的修为数据并转换为 UI 进度（无资质限制）
Future<CultivationLevelDisplay> getDisplayLevelFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('playerData') ?? '{}';
  final json = jsonDecode(raw);

  final BigInt cultivationExp = BigInt.tryParse(json['cultivation'].toString()) ?? BigInt.zero;

  // ✅ 封顶修为值：允许最多到 第10层·0%
  final BigInt maxAllowedExp = getMaxAllowedCultivation();

  // ✅ 封顶逻辑：不得超过 maxLevel 层的起始修为
  final BigInt cappedExp = cultivationExp > maxAllowedExp
      ? maxAllowedExp
      : cultivationExp;

  final info = calculateCultivationLevel(cappedExp);
  final BigInt current = cappedExp - info.levelStart;
  final bool isFull = cappedExp == getMaxAllowedCultivation();

  return CultivationLevelDisplay(
    info.realm,
    info.rank,
    isFull ? info.totalExp : current,
    info.totalExp,
  );
}

/// 🎯 最大允许修为值（第 maxLevel 层的起点）
/// 代表：第 maxLevel 层·0%
BigInt getMaxAllowedCultivation() => totalExpToLevel(CultivationConfig.maxLevel);

