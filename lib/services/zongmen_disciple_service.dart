import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import '../data/favorability_data.dart';
import '../utils/lingshi_util.dart';
import '../widgets/constants/aptitude_table.dart';

class ZongmenDiscipleService {
  static const int maxRealmLevel = 220;

  static int calculatePower(Disciple d) {
    final realHp = (d.hp * (1 + d.extraHp));
    final realAtk = (d.atk * (1 + d.extraAtk));
    final realDef = (d.def * (1 + d.extraDef));
    return (realHp * 0.4 + realAtk * 2 + realDef * 1.5).floor();
  }

  static Map<String, int> calculateInitialAttributes(int aptitude) {
    return {
      'hp': 100 + (aptitude - 31),
      'atk': 20 + (aptitude - 31),
      'def': 10 + (aptitude - 31),
    };
  }

  static Map<String, int> calculateAttributeDeltaBetweenLevels(int fromLevel, int toLevel) {
    int hp = 0, atk = 0, def = 0;

    int curDeltaHp = 75;
    int curDeltaAtk = 15;
    int curDeltaDef = 10;

    for (int level = fromLevel + 1; level <= toLevel; level++) {
      if (level == 1) {
        hp += 50;
        atk += 10;
        def += 5;
        continue;
      }

      hp += curDeltaHp;
      atk += curDeltaAtk;
      def += curDeltaDef;

      if (level % 10 == 0) {
        curDeltaHp *= 2;
        curDeltaAtk *= 2;
        curDeltaDef *= 2;
      }
    }

    return {'hp': hp, 'atk': atk, 'def': def};
  }

  static int parseRealmLayer(String realmName) {
    for (int i = 0; i < aptitudeTable.length; i++) {
      final gate = aptitudeTable[i];
      if (realmName.startsWith(gate.realmName)) {
        final reg = RegExp(r'\d+');
        final match = reg.firstMatch(realmName);
        final rank = match != null ? int.parse(match.group(0)!) : 1;
        return (i * 10) + rank;
      }
    }
    return 1;
  }

  static const _sortOptionKey = 'zongmen_disciple_sort_option';

  static Future<void> saveSortOption(String option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOptionKey, option);
  }

  static Future<String> loadSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOptionKey) ?? 'apt_desc';
  }

  static Future<void> setDisciplePortrait(String discipleId, String imagePath) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final d = box.get(discipleId);
    if (d != null) {
      final updated = d.copyWith(imagePath: imagePath);
      await box.put(d.id, updated);
      debugPrint('🖼️ 已更新立绘：${d.name} -> $imagePath');
    } else {
      debugPrint('⚠️ 未找到弟子: $discipleId');
    }
  }

  static Future<Disciple?> increaseFavorability(String discipleId, {int delta = 1}) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final d = box.get(discipleId);
    if (d != null) {
      final newFavorability = (d.favorability + delta)
          .clamp(0, FavorabilityData.maxFavorability)
          .toInt();
      final updated = d.copyWith(favorability: newFavorability);
      await box.put(d.id, updated);
      return updated;
    }
    return null;
  }

  BigInt getLingShiRequiredForNextLayer(int currentLevel) {
    if (currentLevel < 1) return BigInt.zero;

    int segment = currentLevel ~/ 10;
    int offset = currentLevel % 10;

    BigInt base = BigInt.from(500) * BigInt.from(2).pow(segment);
    BigInt delta = base ~/ BigInt.from(2);

    return base + delta * BigInt.from(offset);
  }

  static String getRealmNameByLevel(int realmLevel) {
    if (realmLevel <= 0) return '凡人';

    final index = (realmLevel - 1) ~/ 10;
    final rank = (realmLevel - 1) % 10 + 1;

    final realm = (index >= 0 && index < aptitudeTable.length)
        ? aptitudeTable[index].realmName
        : aptitudeTable.last.realmName;

    return '$realm$rank层';
  }

  static Future<bool> addCultivationToDisciple(
      Disciple d, {
        required BigInt low,
        required BigInt mid,
        required BigInt high,
        required BigInt supreme,
      }) async {
    final total = (low * lingShiRates[LingShiType.lower]!) +
        (mid * lingShiRates[LingShiType.middle]!) +
        (high * lingShiRates[LingShiType.upper]!) +
        (supreme * lingShiRates[LingShiType.supreme]!);

    if (total == BigInt.zero) {
      debugPrint('🚫 提升失败：投入灵石总和为0');
      return false;
    }

    await ResourcesStorage.subtract('spiritStoneLow', low);
    await ResourcesStorage.subtract('spiritStoneMid', mid);
    await ResourcesStorage.subtract('spiritStoneHigh', high);
    await ResourcesStorage.subtract('spiritStoneSupreme', supreme);

    final prevExp = BigInt.from(d.cultivation);
    final newExp = prevExp + total;
    debugPrint('🧪【初始状态】realmLevel=${d.realmLevel}, cultivation=$prevExp, added=$total');
    debugPrint('🧬【累计修为】newCultivation=$newExp');

    final newLevel = calculateUpgradedRealmLevel(
      currentLevel: 0,
      currentCultivation: BigInt.zero,
      addedCultivation: newExp,
    );

    final upgraded = newLevel > d.realmLevel;
    if (upgraded) {
      final delta = calculateAttributeDeltaBetweenLevels(d.realmLevel, newLevel);
      d.hp += delta['hp']!;
      d.atk += delta['atk']!;
      d.def += delta['def']!;
      debugPrint('📈【属性成长】+HP:${delta['hp']} +ATK:${delta['atk']} +DEF:${delta['def']}');
    }

    d.cultivation = newExp.toInt();
    d.realmLevel = newLevel;

    debugPrint('💾【保存弟子】realmLevel=${d.realmLevel}, cultivation=${d.cultivation}');
    await d.save();
    return upgraded;
  }

  static BigInt getCultivationNeededForNextLevel(int currentLevel) {
    final base = 500.0;
    final ratio = 1.15;
    final needed = base * pow(ratio, currentLevel);
    return BigInt.from(needed.round());
  }

  static int calculateUpgradedRealmLevel({
    required int currentLevel,
    required BigInt currentCultivation,
    required BigInt addedCultivation,
  }) {
    int level = currentLevel;
    BigInt exp = currentCultivation + addedCultivation;

    while (true) {
      if (level >= maxRealmLevel) break;
      final need = getCultivationNeededForNextLevel(level);
      if (exp < need) break;
      exp -= need;
      level += 1;
    }

    return level;
  }

  static String getDisplayLevelFromLayer(int level) {
    return getRealmNameByLevel(level);
  }

  /// 🧮 计算满级所需总修为
  static BigInt getMaxTotalCultivation() {
    BigInt sum = BigInt.zero;
    for (int i = 0; i < maxRealmLevel; i++) {
      sum += getCultivationNeededForNextLevel(i);
    }
    return sum;
  }

}
