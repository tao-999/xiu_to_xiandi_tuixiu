// 📂 lib/models/character.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart'; // 使用现成 Gongfa 模型

/// 👤 Character —— 修士角色类（精简版，只有基础和百分比加成）
class Character {
  final String id;
  String name;
  String gender;
  String career;

  BigInt cultivation;
  double cultivationEfficiency;
  int currentMapStage;

  int aptitude;       // 🌟 独立资质字段
  int realmLevel;     // 🌟 当前修为层数（0 表示凡人）

  /// 🆕 玩家基础移动速度 & 百分比加成（0.15=+15%）
  double moveSpeed;
  double moveSpeedBoost;

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

  /// 🆕 功法改为数组对象
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
    this.moveSpeedBoost = 0.0,
  });

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
    'moveSpeed': moveSpeed,            // 🆕
    'moveSpeedBoost': moveSpeedBoost,  // 🆕
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
    // 🆕 直接就地展开 Gongfa -> Map
    'techniques': techniques.map((g) {
      return {
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
      };
    }).toList(),
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
    aptitude: json['aptitude'] ?? 0,
    realmLevel: json['realmLevel'] ?? 0, // ✅ 默认值为 0，表示凡人
    moveSpeed: (json['moveSpeed'] ?? 200.0).toDouble(),           // 🆕
    moveSpeedBoost: (json['moveSpeedBoost'] ?? 0.0).toDouble(),   // 🆕
    baseHp: json['baseHp'] ?? 100,
    extraHp: (json['extraHp'] ?? 0).toDouble(),
    baseAtk: json['baseAtk'] ?? 10,
    extraAtk: (json['extraAtk'] ?? 0).toDouble(),
    baseDef: json['baseDef'] ?? 5,
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
    // 🆕 解析 List<Gongfa>（就地 new，不引入任何额外 helper）
    techniques: (json['techniques'] is List
        ? (json['techniques'] as List)
        : const <dynamic>[])
        .where((e) => e != null)
        .map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final typeIdx = (m['type'] ?? 0) is num ? (m['type'] as num).toInt() : 0;

      // 时间恢复
      DateTime at;
      final acquired = m['acquiredAt'];
      if (acquired is String) {
        at = DateTime.tryParse(acquired) ?? DateTime.now();
      } else if (acquired is int) {
        at = DateTime.fromMillisecondsSinceEpoch(acquired);
      } else {
        at = DateTime.now();
      }

      return Gongfa(
        id: m['id']?.toString() ?? '',
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
      );
    }).toList(),
    createdAt: json['createdAt'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  );

  factory Character.empty() => Character(
    id: '',
    name: '未命名修士',
    gender: '男',
    career: '散修',
    cultivation: BigInt.zero,
    aptitude: 0,
    realmLevel: 0, // ✅ 初始化为 0 层
    cultivationEfficiency: 1.0,
    currentMapStage: 1,
    moveSpeed: 200.0,        // 🆕
    moveSpeedBoost: 0.0,     // 🆕
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
    techniques: const <Gongfa>[], // 🆕
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
