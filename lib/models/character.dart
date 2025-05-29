class Character {
  final String id;
  String name;
  String gender;
  String career;
  double cultivation; // 当前修为值
  double cultivationEfficiency; // 修炼效率倍率，默认 1.0

  // 核心基础属性
  int hp;
  int atk;
  int def;
  double atkSpeed;

  // 战斗相关属性
  double critRate;
  double critDamage;
  double dodgeRate;
  double lifeSteal;
  double breakArmorRate;
  double luckRate;
  double comboRate;

  // 光环类属性
  double evilAura;
  double weakAura;
  double corrosionAura;

  // 五行属性（代表资质，不参与战力）
  Map<String, int> elements;

  String technique;

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.career,
    required this.cultivation,
    required this.hp,
    required this.atk,
    required this.def,
    required this.atkSpeed,
    required this.critRate,
    required this.critDamage,
    required this.dodgeRate,
    required this.lifeSteal,
    required this.breakArmorRate,
    required this.luckRate,
    required this.comboRate,
    required this.evilAura,
    required this.weakAura,
    required this.corrosionAura,
    required this.elements,
    required this.technique,
    this.cultivationEfficiency = 1.0, // 新增字段，默认倍率为 1.0
  });

  int get totalElement => elements.values.fold(0, (a, b) => a + b);

  int get power {
    return (
        hp * 0.4 +
            atk * 2 +
            def * 1.5
    ).toInt();
  }

  double get growthMultiplier => 1 + totalElement / 100;

  void applyBreakthroughBonus() {
    final m = growthMultiplier;
    hp = (hp * m).round();
    atk = (atk * m).round();
    def = (def * m).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'career': career,
    'cultivation': cultivation,
    'cultivationEfficiency': cultivationEfficiency, // 👈 保存效率字段
    'hp': hp,
    'atk': atk,
    'def': def,
    'atkSpeed': atkSpeed,
    'critRate': critRate,
    'critDamage': critDamage,
    'dodgeRate': dodgeRate,
    'lifeSteal': lifeSteal,
    'breakArmorRate': breakArmorRate,
    'luckRate': luckRate,
    'comboRate': comboRate,
    'evilAura': evilAura,
    'weakAura': weakAura,
    'corrosionAura': corrosionAura,
    'elements': elements,
    'technique': technique,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    career: json['career'],
    cultivation: (json['cultivation'] ?? 0).toDouble(),
    cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(), // 👈 加载效率字段
    hp: json['hp'],
    atk: json['atk'],
    def: json['def'],
    atkSpeed: (json['atkSpeed'] ?? 1.5).toDouble(),
    critRate: (json['critRate'] ?? 0.0).toDouble(),
    critDamage: (json['critDamage'] ?? 0.0).toDouble(),
    dodgeRate: (json['dodgeRate'] ?? 0.0).toDouble(),
    lifeSteal: (json['lifeSteal'] ?? 0.0).toDouble(),
    breakArmorRate: (json['breakArmorRate'] ?? 0.0).toDouble(),
    luckRate: (json['luckRate'] ?? 0.0).toDouble(),
    comboRate: (json['comboRate'] ?? 0.0).toDouble(),
    evilAura: (json['evilAura'] ?? 0.0).toDouble(),
    weakAura: (json['weakAura'] ?? 0.0).toDouble(),
    corrosionAura: (json['corrosionAura'] ?? 0.0).toDouble(),
    elements: Map<String, int>.from(json['elements']),
    technique: json['technique'],
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: 0.0,
    cultivationEfficiency: 1.0,
    hp: 100,
    atk: 10,
    def: 5,
    atkSpeed: 1.5,
    critRate: 0.0,
    critDamage: 0.0,
    dodgeRate: 0.0,
    lifeSteal: 0.0,
    breakArmorRate: 0.0,
    luckRate: 0.0,
    comboRate: 0.0,
    evilAura: 0.0,
    weakAura: 0.0,
    corrosionAura: 0.0,
    elements: {
      'gold': 0,
      'wood': 0,
      'water': 0,
      'fire': 0,
      'earth': 0,
    },
    technique: '无名功法',
  );
}
