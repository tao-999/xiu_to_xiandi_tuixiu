// 📂 lib/models/character.dart
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart'; // 直接用现成 Gongfa 模型

/// 👤 Character —— 纯数据模型（无业务计算方法）
class Character {
  final String id;
  String name;
  String gender;
  String career;

  BigInt cultivation;
  double cultivationEfficiency;
  int currentMapStage;

  int aptitude;       // 资质
  int realmLevel;     // 当前修为层数（0=凡人）

  /// 基础移动速度（单位按你项目定义）
  double moveSpeed;

  /// 基础属性（包含丹药等累加）
  int baseHp;
  int baseAtk;
  int baseDef;

  /// 装备百分比加成
  double extraHp;
  double extraAtk;
  double extraDef;

  double atkSpeed;

  double critRate;
  double critDamage;
  double dodgeRate;
  double lifeSteal;
  double breakArmorRate;
  double luckRate;
  double comboRate;

  double evilAura;
  double weakAura;
  double corrosionAura;

  Map<String, int> elements;

  /// 功法：直接用 Gongfa（含 speedBoost、atk/def/hpBoost 等）
  List<Gongfa> techniques;

  final int createdAt;

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.career,
    required this.cultivation,
    required this.aptitude,
    required this.realmLevel,
    required this.baseHp,
    required this.extraHp,
    required this.baseAtk,
    required this.extraAtk,
    required this.baseDef,
    required this.extraDef,
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
    required this.techniques,
    required this.createdAt,
    this.cultivationEfficiency = 1.0,
    this.currentMapStage = 1,
    this.moveSpeed = 200.0,
  });

  // —— 序列化（保留） ——
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'career': career,
    'cultivation': cultivation.toString(),
    'cultivationEfficiency': cultivationEfficiency,
    'currentMapStage': currentMapStage,
    'aptitude': aptitude,
    'realmLevel': realmLevel,
    'moveSpeed': moveSpeed,
    'baseHp': baseHp,
    'extraHp': extraHp,
    'baseAtk': baseAtk,
    'extraAtk': extraAtk,
    'baseDef': baseDef,
    'extraDef': extraDef,
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
    'techniques': techniques.map(_gongfaToMap).toList(), // 用顶层工具函数
    'createdAt': createdAt,
  };

  factory Character.fromJson(Map<String, dynamic> json) {
    List<Gongfa> parseTechniques() {
      final dyn = json['techniques'];
      if (dyn is List) {
        return dyn
            .where((e) => e != null)
            .map((e) => _gongfaFromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      // 兼容旧存档：只有单个 'technique': '太玄经'
      final legacy = json['technique']?.toString();
      if (legacy != null && legacy.isNotEmpty) {
        return [
          Gongfa(
            id: legacy,
            name: legacy,
            level: 1,
            type: GongfaType.special,
            description: legacy,
            isLearned: true,
            count: 1,
            speedBoost: 0.0,
          ),
        ];
      }
      return <Gongfa>[];
    }

    return Character(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '未命名修士',
      gender: json['gender']?.toString() ?? '男',
      career: json['career']?.toString() ?? '散修',
      cultivation: BigInt.tryParse('${json['cultivation']}') ?? BigInt.zero,
      cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(),
      currentMapStage: (json['currentMapStage'] ?? 1) is num
          ? (json['currentMapStage'] as num).toInt()
          : 1,
      aptitude: (json['aptitude'] ?? 0) is num ? (json['aptitude'] as num).toInt() : 0,
      realmLevel: (json['realmLevel'] ?? 0) is num ? (json['realmLevel'] as num).toInt() : 0,
      moveSpeed: (json['moveSpeed'] ?? 200.0).toDouble(),
      baseHp: (json['baseHp'] ?? 100) is num ? (json['baseHp'] as num).toInt() : 100,
      extraHp: (json['extraHp'] ?? 0).toDouble(),
      baseAtk: (json['baseAtk'] ?? 10) is num ? (json['baseAtk'] as num).toInt() : 10,
      extraAtk: (json['extraAtk'] ?? 0).toDouble(),
      baseDef: (json['baseDef'] ?? 5) is num ? (json['baseDef'] as num).toInt() : 5,
      extraDef: (json['extraDef'] ?? 0).toDouble(),
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
      elements: Map<String, int>.fromEntries(
        (json['elements'] as Map<String, dynamic>? ?? {}).entries.map(
              (e) => MapEntry(e.key, (e.value as num).toInt()),
        ),
      ),
      techniques: parseTechniques(),
      createdAt: (json['createdAt'] ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000)) is num
          ? (json['createdAt'] as num).toInt()
          : (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );
  }

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: BigInt.zero,
    aptitude: 0,
    realmLevel: 0,
    cultivationEfficiency: 1.0,
    currentMapStage: 1,
    moveSpeed: 200.0,
    baseHp: 100,
    extraHp: 0,
    baseAtk: 10,
    extraAtk: 0,
    baseDef: 5,
    extraDef: 0,
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
    elements: const {
      'gold': 0,
      'wood': 0,
      'water': 0,
      'fire': 0,
      'earth': 0,
    },
    techniques: const <Gongfa>[],
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

/// —— 顶层工具（不是模型方法）：Gongfa ↔ Map ——
/// 这样 Character 保持“纯数据”，序列化细节放到顶层工具里。
Map<String, dynamic> _gongfaToMap(Gongfa g) => {
  'id': g.id,
  'name': g.name,
  'level': g.level,
  'type': g.type.index, // 枚举保存为 index
  'description': g.description,
  'atkBoost': g.atkBoost,
  'defBoost': g.defBoost,
  'hpBoost': g.hpBoost,
  'iconPath': g.iconPath,
  'isLearned': g.isLearned,
  'acquiredAt': g.acquiredAt.toIso8601String(),
  'count': g.count,
  'speedBoost': g.speedBoost, // 👈 速度加成
};

Gongfa _gongfaFromMap(Map<String, dynamic> m) {
  final typeIdx = (m['type'] ?? 0) is num ? (m['type'] as num).toInt() : 0;
  final acquired = m['acquiredAt'];
  DateTime at;
  if (acquired is String) {
    at = DateTime.tryParse(acquired) ?? DateTime.now();
  } else if (acquired is int) {
    at = DateTime.fromMillisecondsSinceEpoch(acquired);
  } else {
    at = DateTime.now();
  }

  return Gongfa(
    id: m['id']?.toString() ?? m['name']?.toString() ?? '',
    name: m['name']?.toString() ?? '无名功法',
    level: (m['level'] ?? 1) is num ? (m['level'] as num).toInt() : 1,
    type: GongfaType.values[(typeIdx).clamp(0, GongfaType.values.length - 1)],
    description: m['description']?.toString() ?? '',
    atkBoost: (m['atkBoost'] ?? 0) is num ? (m['atkBoost'] as num).toInt() : 0,
    defBoost: (m['defBoost'] ?? 0) is num ? (m['defBoost'] as num).toInt() : 0,
    hpBoost: (m['hpBoost'] ?? 0) is num ? (m['hpBoost'] as num).toInt() : 0,
    iconPath: m['iconPath']?.toString() ?? '',
    isLearned: (m['isLearned'] ?? false) == true,
    acquiredAt: at,
    count: (m['count'] ?? 1) is num ? (m['count'] as num).toInt() : 1,
    speedBoost: (m['speedBoost'] ?? 0).toDouble(),
  );
}
