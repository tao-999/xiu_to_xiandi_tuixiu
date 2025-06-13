import 'dart:math';

import '../data/all_pill_recipes.dart';
import '../models/pill_recipe.dart';

class PillsService {
  /// 生成所有丹方列表（每阶3种：攻击、防御、血气）
  static List<PillRecipe> generateAllPillRecipes() {
    final List<PillRecipe> recipes = [];

    for (int level = 1; level <= levelMaterials.length; level++) {
      final materials = levelMaterials[level - 1];

      for (final entry in pillInfoMap.entries) {
        final PillType type = entry.key;
        final Map<String, String> info = entry.value.first; // ✅ 修复点
        final String namePrefix = info['prefix']!;
        final String description = info['desc']!;
        final int effectValue = _getEffectValue(type, level);

        recipes.add(PillRecipe(
          name: '$namePrefix·${_getTypeName(type)}',
          type: type,
          level: level,
          description: description,
          usageTypes: [_getTypeName(type)],
          requirements: [
            materials[0],
            materials[1],
            _getMaterialForType(type, materials),
          ],
          effectValue: effectValue,
        ));
      }
    }

    return recipes;
  }

  /// 获取效果值
  static int _getEffectValue(PillType type, int level) {
    double base;
    double multiplier;

    switch (type) {
      case PillType.attack:
        base = 10;
        multiplier = 1.6;
        break;
      case PillType.defense:
        base = 5;
        multiplier = 1.55;
        break;
      case PillType.health:
        base = 50;
        multiplier = 1.7;
        break;
    }

    return (base * pow(multiplier, level - 1)).toInt();
  }

  /// 根据类型选取专属第三种药材
  static String _getMaterialForType(PillType type, List<String> materials) {
    switch (type) {
      case PillType.attack:
        return materials[2];
      case PillType.defense:
        return materials[3];
      case PillType.health:
        return materials[4];
    }
  }

  /// 类型名称转文字
  static String _getTypeName(PillType type) {
    switch (type) {
      case PillType.attack:
        return '攻击';
      case PillType.defense:
        return '防御';
      case PillType.health:
        return '血气';
    }
  }
}
