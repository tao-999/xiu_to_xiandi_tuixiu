import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

/// 👤 Character —— 修士角色类
/// 记录角色基本信息、属性、资质、修为、地图阶段与资源信息等
class Character {
  final String id;
  String name;
  String gender;
  String career;
  double cultivation; // 当前修为值
  double cultivationEfficiency; // 修炼效率倍率，默认 1.0
  int currentMapStage; // ✅ 当前挂机地图阶段（新增）

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

  Resources resources; // ✅ 加入资源对象（灵石、灵气等）

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
    required this.resources, // ✅ 加入资源初始化
    this.cultivationEfficiency = 1.0,
    this.currentMapStage = 1, // ✅ 默认地图为第1阶
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
    'cultivationEfficiency': cultivationEfficiency,
    'currentMapStage': currentMapStage, // ✅ 加入序列化
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
    'resources': resources.toMap(), // ✅ 序列化资源
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    career: json['career'],
    cultivation: (json['cultivation'] ?? 0).toDouble(),
    cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(),
    currentMapStage: json['currentMapStage'] ?? 1,

    // ✅ 关键：确保类型安全转成 int，防止 prefs 中存了 double
    hp: (json['hp'] as num).toInt(),
    atk: (json['atk'] as num).toInt(),
    def: (json['def'] as num).toInt(),

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

    // ✅ 五行转 int，防止被 double 污染
    elements: Map<String, int>.fromEntries(
      (json['elements'] as Map<String, dynamic>).entries.map(
            (e) => MapEntry(e.key, (e.value as num).toInt()),
      ),
    ),

    technique: json['technique'],
    resources: Resources.fromMap(json['resources'] ?? {}),
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: 0.0,
    cultivationEfficiency: 1.0,
    currentMapStage: 1, // ✅ 空对象默认第1阶地图
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
    resources: Resources(), // ✅ 空角色初始资源为 0
  );
}
