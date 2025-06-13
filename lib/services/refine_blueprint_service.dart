import 'dart:math';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/data/all_refine_blueprints.dart';

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
