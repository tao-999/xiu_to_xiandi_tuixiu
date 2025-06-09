import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/models/resources.dart';
import '../services/global_event_bus.dart';

/// 👤 Character —— 修士角色类
/// 记录角色基本信息、属性、资质、修为、地图阶段与资源信息等
class Character {
  final String id;
  String name;
  String gender;
  String career;
  double cultivation;
  double cultivationEfficiency;
  int currentMapStage;

  int hp;
  int atk;
  int def;
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

  final int createdAt; // 新增：创角时间戳（秒）

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
    required this.resources,
    required this.createdAt,
    this.cultivationEfficiency = 1.0,
    this.currentMapStage = 1,
  });

  int get totalElement => elements.values.fold(0, (a, b) => a + b);
  double get growthMultiplier => 1 + totalElement / 100;

  void applyBreakthroughBonus({required int layer}) {
    // 每层固定成长
    const int baseHp = 50;
    const int baseAtk = 10;
    const int baseDef = 5;

    final double factor = 1 + totalElement / 200.0;

    final int hpGain = (baseHp * factor).round();
    final int atkGain = (baseAtk * factor).round();
    final int defGain = (baseDef * factor).round();

    hp += hpGain;
    atk += atkGain;
    def += defGain;

    debugPrint("💥 层数 $layer 突破成功：hp+$hpGain, atk+$atkGain, def+$defGain");
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'career': career,
    'cultivation': cultivation,
    'cultivationEfficiency': cultivationEfficiency,
    'currentMapStage': currentMapStage,
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
    'resources': resources.toMap(),
    'createdAt': createdAt,
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    career: json['career'],
    cultivation: (json['cultivation'] ?? 0).toDouble(),
    cultivationEfficiency: (json['cultivationEfficiency'] ?? 1.0).toDouble(),
    currentMapStage: json['currentMapStage'] ?? 1,
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
    elements: Map<String, int>.fromEntries(
      (json['elements'] as Map<String, dynamic>).entries.map(
            (e) => MapEntry(e.key, (e.value as num).toInt()),
      ),
    ),
    technique: json['technique'],
    resources: Resources.fromMap(json['resources'] ?? {}),
    createdAt: json['createdAt'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: 0.0,
    cultivationEfficiency: 1.0,
    currentMapStage: 1,
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
    resources: Resources(),
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
