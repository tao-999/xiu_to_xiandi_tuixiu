import 'package:flutter/cupertino.dart';

/// 👤 Character —— 修士角色类（纯数据，不含任何资源）
class Character {
  final String id;
  String name;
  String gender;
  String career;

  BigInt cultivation;
  double cultivationEfficiency;
  int currentMapStage;

  int baseHp;
  int extraHp;
  int pillBonusHp;

  int baseAtk;
  int extraAtk;
  int pillBonusAtk;

  int baseDef;
  int extraDef;
  int pillBonusDef;

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

  final int createdAt;

  Character({
    required this.id,
    required this.name,
    required this.gender,
    required this.career,
    required this.cultivation,
    required this.baseHp,
    required this.extraHp,
    required this.pillBonusHp,
    required this.baseAtk,
    required this.extraAtk,
    required this.pillBonusAtk,
    required this.baseDef,
    required this.extraDef,
    required this.pillBonusDef,
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
    required this.createdAt,
    this.cultivationEfficiency = 1.0,
    this.currentMapStage = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'career': career,
    'cultivation': cultivation.toString(),
    'cultivationEfficiency': cultivationEfficiency,
    'currentMapStage': currentMapStage,
    'baseHp': baseHp,
    'extraHp': extraHp,
    'pillBonusHp': pillBonusHp,
    'baseAtk': baseAtk,
    'extraAtk': extraAtk,
    'pillBonusAtk': pillBonusAtk,
    'baseDef': baseDef,
    'extraDef': extraDef,
    'pillBonusDef': pillBonusDef,
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
    'createdAt': createdAt,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    career: json['career'],
    cultivation: BigInt.tryParse(json['cultivation'].toString()) ?? BigInt.zero,
    cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(),
    currentMapStage: json['currentMapStage'] ?? 1,
    baseHp: json['baseHp'] ?? 100,
    extraHp: json['extraHp'] ?? 0,
    pillBonusHp: json['pillBonusHp'] ?? 0,
    baseAtk: json['baseAtk'] ?? 10,
    extraAtk: json['extraAtk'] ?? 0,
    pillBonusAtk: json['pillBonusAtk'] ?? 0,
    baseDef: json['baseDef'] ?? 5,
    extraDef: json['extraDef'] ?? 0,
    pillBonusDef: json['pillBonusDef'] ?? 0,
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
    createdAt: json['createdAt'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: BigInt.zero,
    cultivationEfficiency: 1.0,
    currentMapStage: 1,
    baseHp: 100,
    extraHp: 0,
    pillBonusHp: 0,
    baseAtk: 10,
    extraAtk: 0,
    pillBonusAtk: 0,
    baseDef: 5,
    extraDef: 0,
    pillBonusDef: 0,
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
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
