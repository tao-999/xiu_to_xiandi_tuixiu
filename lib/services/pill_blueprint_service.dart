import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/all_pill_recipes.dart';
import '../models/pill_blueprint.dart';
import '../utils/lingshi_util.dart';

class PillBlueprintService {
  static const _ownedKey = 'ownedPillBlueprintKeys';

  /// ✅ 生成所有丹方图纸（每阶3种类型）
  static List<PillBlueprint> generateAllBlueprints() {
    final List<PillBlueprint> result = [];

    for (int level = 1; level <= levelMaterials.length; level++) {
      for (final entry in pillInfoMap.entries) {
        final PillBlueprintType type = _convert(entry.key);
        final Map<String, String> info = entry.value.first;

        result.add(PillBlueprint(
          name: '${info['prefix']}·${_getTypeName(type)}',
          type: type,
          level: level,
          description: info['desc']!,
          effectValue: _getEffectValue(type, level),
          iconPath: info['icon']!,
        ));
      }
    }

    return result;
  }

  /// ✅ 添加一个图纸记录
  static Future<void> addPillBlueprintKey(PillBlueprint bp) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> keys = prefs.getStringList(_ownedKey) ?? [];
    if (!keys.contains(bp.uniqueKey)) {
      keys.add(bp.uniqueKey);
      await prefs.setStringList(_ownedKey, keys);
    }
  }

  /// ✅ 获取已有图纸 Key 列表
  static Future<Set<String>> getPillBlueprintKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_ownedKey) ?? []).toSet();
  }

  /// ✅ 获取价格：按阶数判断灵石类型 + 金额
  static BlueprintPrice getBlueprintPrice(int level) {
    late LingShiType type;
    late BigInt totalLowerValue;

    if (level <= 6) {
      type = LingShiType.lower;
      totalLowerValue = BigInt.from(5000 * pow(2, level - 1)); // 5K ~ 160K
    } else if (level <= 12) {
      type = LingShiType.middle;
      final local = level - 6;
      totalLowerValue = BigInt.from(1_000_000 * pow(2, local)); // 1M ~ 64M ✅ 中品段开跳
    } else if (level <= 18) {
      type = LingShiType.upper;
      final local = level - 12;
      totalLowerValue = BigInt.from(2_000_000_000 * pow(2, local)); // 2B ~ 128B ✅ 上品
    } else {
      type = LingShiType.supreme;
      final local = level - 18;
      totalLowerValue = BigInt.from(4_000_000_000_000 * pow(2, local)); // 4T ~ 16T ✅ 极品
    }

    final rate = lingShiRates[type]!; // 1000 / 1M / 1B
    final amount = ((totalLowerValue + rate - BigInt.one) ~/ rate).toInt();

    return BlueprintPrice(type: type, amount: amount);
  }

  /// ✅ 计算效果值（用于展示）
  static int _getEffectValue(PillBlueprintType type, int level) {
    double base;
    double multiplier;

    switch (type) {
      case PillBlueprintType.attack:
        base = 10;
        multiplier = 1.6;
        break;
      case PillBlueprintType.defense:
        base = 5;
        multiplier = 1.55;
        break;
      case PillBlueprintType.health:
        base = 50;
        multiplier = 1.7;
        break;
    }

    return (base * pow(multiplier, level - 1)).toInt();
  }

  static String _getTypeName(PillBlueprintType type) {
    switch (type) {
      case PillBlueprintType.attack:
        return '攻击';
      case PillBlueprintType.defense:
        return '防御';
      case PillBlueprintType.health:
        return '血气';
    }
  }

  static PillBlueprintType _convert(dynamic t) {
    switch (t.toString()) {
      case 'PillType.attack':
        return PillBlueprintType.attack;
      case 'PillType.defense':
        return PillBlueprintType.defense;
      case 'PillType.health':
        return PillBlueprintType.health;
      default:
        throw Exception('无法转换类型：$t');
    }
  }
}

/// ✅ 图纸价格结构体
class BlueprintPrice {
  final LingShiType type;
  final int amount;

  const BlueprintPrice({
    required this.type,
    required this.amount,
  });
}
