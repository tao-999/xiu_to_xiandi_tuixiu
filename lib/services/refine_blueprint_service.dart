import 'dart:math';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/data/all_refine_blueprints.dart';

enum LingShiType { lower, middle, high, supreme }

class BlueprintPrice {
  final BigInt amount;
  final LingShiType type;

  BlueprintPrice({required this.amount, required this.type});
}

class RefineBlueprintService {
  /// 生成所有蓝图（每阶 × 每类型 × 对应图纸）
  static List<RefineBlueprint> generateAllBlueprints() {
    final List<RefineBlueprint> result = [];

    for (int level = 1; level <= levelForgeMaterials.length; level++) {
      final materials = levelForgeMaterials[level - 1];

      blueprintInfoMap.forEach((type, infoList) {
        for (final info in infoList) {
          result.add(
            RefineBlueprint(
              name: '${info['prefix']} · ${level}阶',
              description: info['desc'] ?? '',
              level: level,
              type: type,
              materials: materials.sublist(0, 3),
              attackBoost: _getAttackBoost(type, level),
              defenseBoost: _getDefenseBoost(type, level),
              healthBoost: _getHealthBoost(type, level),
              iconPath: info['icon'],
            ),
          );
        }
      });
    }

    return result;
  }

  // ======= 核心增幅函数 ========

  static const int maxLevel = 21;

  static const int _atkStart = 20;
  static const int _atkEnd = 100000;
  static final double _atkMultiplier =
  pow(_atkEnd / _atkStart, 1 / (maxLevel - 1)).toDouble();

  static const int _defStart = 15;
  static const int _defEnd = 80000;
  static final double _defMultiplier =
  pow(_defEnd / _defStart, 1 / (maxLevel - 1)).toDouble();

  static const int _hpStart = 30;
  static const int _hpEnd = 200000;
  static final double _hpMultiplier =
  pow(_hpEnd / _hpStart, 1 / (maxLevel - 1)).toDouble();

  static int _getAttackBoost(BlueprintType type, int level) {
    return type == BlueprintType.weapon
        ? (_atkStart * pow(_atkMultiplier, level - 1)).round()
        : 0;
  }

  static int _getDefenseBoost(BlueprintType type, int level) {
    return type == BlueprintType.armor
        ? (_defStart * pow(_defMultiplier, level - 1)).round()
        : 0;
  }

  static int _getHealthBoost(BlueprintType type, int level) {
    return type == BlueprintType.accessory
        ? (_hpStart * pow(_hpMultiplier, level - 1)).round()
        : 0;
  }

  /// 获取图纸的主要效果（类型 + 数值）
  static Map<String, dynamic> getEffectMeta(RefineBlueprint blueprint) {
    if (blueprint.attackBoost > 0) {
      return {'type': '攻击', 'value': blueprint.attackBoost};
    } else if (blueprint.defenseBoost > 0) {
      return {'type': '防御', 'value': blueprint.defenseBoost};
    } else if (blueprint.healthBoost > 0) {
      return {'type': '气血', 'value': blueprint.healthBoost};
    } else {
      return {'type': '', 'value': 0};
    }
  }

  /// 获取蓝图对应的价格（自动换算灵石种类）
  static BlueprintPrice getBlueprintPrice(int level) {
    if (level <= 0 || level > 21) {
      throw ArgumentError('蓝图阶数必须在 1~21 之间');
    }

    if (level <= 5) {
      // 下品灵石（起价 5000，×3）
      final base = 5000 * pow(3, level - 1).toInt();
      return BlueprintPrice(amount: BigInt.from(base), type: LingShiType.lower);
    } else if (level <= 10) {
      // 中品灵石（起价 3000，×2.5）
      final base = 3000 * pow(2.5, level - 6).toInt();
      return BlueprintPrice(amount: BigInt.from(base), type: LingShiType.middle);
    } else if (level <= 15) {
      // 上品灵石（起价 2000，×2.5）
      final base = 2000 * pow(2.5, level - 11).toInt();
      return BlueprintPrice(amount: BigInt.from(base), type: LingShiType.high);
    } else {
      // 极品灵石（起价 1000，×2.5）
      final base = 1000 * pow(2.5, level - 16).toInt();
      return BlueprintPrice(amount: BigInt.from(base), type: LingShiType.supreme);
    }
  }

  // ======= 筛选器 ========

  static List<RefineBlueprint> filterByType(BlueprintType type) {
    return generateAllBlueprints().where((b) => b.type == type).toList();
  }

  static List<RefineBlueprint> filterByLevel(int level) {
    return generateAllBlueprints().where((b) => b.level == level).toList();
  }

  static List<RefineBlueprint> filterByLevelAndType(int level, BlueprintType type) {
    return generateAllBlueprints()
        .where((b) => b.level == level && b.type == type)
        .toList();
  }
}
