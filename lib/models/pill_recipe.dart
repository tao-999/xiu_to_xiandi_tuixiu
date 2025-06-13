// lib/models/pill_recipe.dart

enum PillType { attack, defense, health }

class PillRecipe {
  final String name;
  final PillType type;
  final int level;
  final String description;
  final List<String> usageTypes;
  final List<String> requirements;
  final int effectValue;

  const PillRecipe({
    required this.name,
    required this.type,
    required this.level,
    required this.description,
    required this.usageTypes,
    required this.requirements,
    required this.effectValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'level': level,
      'description': description,
      'usageTypes': usageTypes,
      'requirements': requirements,
      'effectValue': effectValue,
    };
  }

  factory PillRecipe.fromMap(Map<String, dynamic> map) {
    return PillRecipe(
      name: map['name'],
      type: PillType.values.firstWhere((e) => e.name == map['type']),
      level: map['level'],
      description: map['description'],
      usageTypes: List<String>.from(map['usageTypes']),
      requirements: List<String>.from(map['requirements']),
      effectValue: map['effectValue'],
    );
  }
}
