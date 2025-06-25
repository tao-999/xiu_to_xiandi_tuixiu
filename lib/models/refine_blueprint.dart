enum BlueprintType { weapon, armor, accessory }

class RefineBlueprint {
  final String name;
  final String description;
  final int level;
  final BlueprintType type;
  final List<String> materials;

  /// 🔥 属性增幅字段（单位：百分比，整数，不含%符号）
  final int attackBoost;
  final int defenseBoost;
  final int healthBoost;

  /// 🧱 图纸图标路径（如：'wuqi_gongji.png'）
  final String? iconPath;

  RefineBlueprint({
    required this.name,
    required this.description,
    required this.level,
    required this.type,
    required this.materials,
    this.attackBoost = 0,
    this.defenseBoost = 0,
    this.healthBoost = 0,
    this.iconPath,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'level': level,
    'type': type.name, // ✅ 枚举转字符串
    'materials': materials,
    'attackBoost': attackBoost,
    'defenseBoost': defenseBoost,
    'healthBoost': healthBoost,
    'iconPath': iconPath,
  };

  factory RefineBlueprint.fromMap(Map<String, dynamic> map) {
    return RefineBlueprint(
      name: map['name'],
      description: map['description'],
      level: map['level'],
      type: BlueprintType.values.firstWhere((e) => e.name == map['type']),
      materials: List<String>.from(map['materials']),
      attackBoost: map['attackBoost'] ?? 0,
      defenseBoost: map['defenseBoost'] ?? 0,
      healthBoost: map['healthBoost'] ?? 0,
      iconPath: map['iconPath'],
    );
  }

  // 放在 RefineBlueprint 类内部
  String get typeLabel {
    switch (type) {
      case BlueprintType.weapon:
        return '武器';
      case BlueprintType.armor:
        return '防具';
      case BlueprintType.accessory:
        return '饰品';
    }
  }
}
