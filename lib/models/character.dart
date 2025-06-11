import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';

/// 👤 Character —— 修士角色类（纯数据，不含任何逻辑）
class Character {
  final String id;
  String name;
  String gender;
  String career;

  /// ✅ 修为改为 BigInt 类型
  BigInt cultivation;

  double cultivationEfficiency;
  int currentMapStage;

  // 拆分基础属性 + 附加属性
  int baseHp;
  int extraHp;

  int baseAtk;
  int extraAtk;

  int baseDef;
  int extraDef;

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
  String technique;

  Resources resources;
  final int createdAt; // 创建时间戳（秒）

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.career,
    required this.cultivation,
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
    required this.technique,
    required this.resources,
    required this.createdAt,
    this.cultivationEfficiency = 1.0,
    this.currentMapStage = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'career': career,
    'cultivation': cultivation.toString(), // ✅ BigInt 转字符串保存
    'cultivationEfficiency': cultivationEfficiency,
    'currentMapStage': currentMapStage,
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
    'technique': technique,
    'resources': resources.toMap(),
    'createdAt': createdAt,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    career: json['career'],
    cultivation: BigInt.tryParse(json['cultivation'].toString()) ?? BigInt.zero, // ✅ BigInt 解析
    cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(),
    currentMapStage: json['currentMapStage'] ?? 1,
    baseHp: (json['baseHp'] ?? 100) as int,
    extraHp: (json['extraHp'] ?? 0) as int,
    baseAtk: (json['baseAtk'] ?? 10) as int,
    extraAtk: (json['extraAtk'] ?? 0) as int,
    baseDef: (json['baseDef'] ?? 5) as int,
    extraDef: (json['extraDef'] ?? 0) as int,
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
    technique: json['technique'] ?? '无名功法',
    resources: Resources.fromMap(json['resources'] ?? {}),
    createdAt: json['createdAt'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: BigInt.zero, // ✅ 初始化 BigInt.zero
    cultivationEfficiency: 1.0,
    currentMapStage: 1,
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
    elements: {
      'gold': 0,
      'wood': 0,
      'water': 0,
      'fire': 0,
      'earth': 0,
    },
    technique: '无名功法',
    resources: Resources(),
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
