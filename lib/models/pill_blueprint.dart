enum PillBlueprintType { attack, defense, health }

class PillBlueprint {
  final String name;
  final PillBlueprintType type;
  final int level;
  final String description;
  final int effectValue;
  final String iconPath;

  const PillBlueprint({
    required this.name,
    required this.type,
    required this.level,
    required this.description,
    required this.effectValue,
    required this.iconPath,
  });

  String get typeLabel {
    switch (type) {
      case PillBlueprintType.attack:
        return '攻击';
      case PillBlueprintType.defense:
        return '防御';
      case PillBlueprintType.health:
        return '血气';
    }
  }

  String get uniqueKey => '${type.name}-$level';
}
