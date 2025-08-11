// 📂 lib/models/character.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

class Character {
  final String id;
  String name;
  String gender;
  String career;

  BigInt cultivation;
  double cultivationEfficiency;
  int currentMapStage;

  int aptitude;
  int realmLevel;

  double moveSpeed;
  double moveSpeedBoost;

  int baseHp;
  int baseAtk;
  int baseDef;

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

  /// 运行期：功法对象列表（可能为空）
  List<Gongfa> techniques;

  /// 🆕 持久化：功法索引 {type: [ids]}
  Map<String, List<String>> techniquesMap;

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
    Map<String, List<String>>? techniquesMap,
  }) : techniquesMap = techniquesMap ?? <String, List<String>>{};

  /// ✅ 序列化：写 {type: [ids]}；若 map 为空，则由对象列表聚合生成
  Map<String, dynamic> toJson() {
    Map<String, List<String>> mapOut = techniquesMap;
    if (mapOut.isEmpty && techniques.isNotEmpty) {
      final m = <String, List<String>>{};
      for (final g in techniques) {
        final k = g.type.name; // e.g. 'movement'
        (m[k] ??= <String>[]).add(g.id);
      }
      mapOut = m.map((k, v) => MapEntry(k, v.toSet().toList())); // 去重
    }

    return {
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
      'moveSpeedBoost': moveSpeedBoost,
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
      // 🔥 只存索引 map
      'techniques': mapOut,
      'createdAt': createdAt,
    };
  }

  /// ✅ 反序列化：兼容三种历史格式
  /// - Map<String, List>: 新格式 → techniquesMap
  /// - List<Map>: 旧完整对象 → 解析为 techniques（并可聚合出 map）
  /// - List<String>: 旧仅ID → 按 movement 槽兜底：{'movement':[ids]}
  factory Character.fromJson(Map<String, dynamic> json) {
    final elements = Map<String, int>.fromEntries(
      (json['elements'] as Map<String, dynamic>? ?? {}).entries.map(
            (e) => MapEntry(e.key, (e.value as num).toInt()),
      ),
    );

    final rawTech = json['techniques'];
    final parsedTechniques = <Gongfa>[];
    Map<String, List<String>> parsedMap = <String, List<String>>{};

    if (rawTech is Map) {
      // ✅ 新格式：{type: [ids]}
      final m = Map<String, dynamic>.from(rawTech);
      m.forEach((k, v) {
        if (v is List) {
          parsedMap[k] = v.whereType<String>().toList();
        }
      });
    } else if (rawTech is List) {
      if (rawTech.isNotEmpty && rawTech.first is Map) {
        // ✅ 老格式：内联对象
        for (final e in rawTech) {
          final m = Map<String, dynamic>.from(e as Map);
          final typeIdx =
          (m['type'] ?? 0) is num ? (m['type'] as num).toInt() : 0;

          DateTime at;
          final acquired = m['acquiredAt'];
          if (acquired is String) {
            at = DateTime.tryParse(acquired) ?? DateTime.now();
          } else if (acquired is int) {
            at = DateTime.fromMillisecondsSinceEpoch(acquired);
          } else {
            at = DateTime.now();
          }

          final g = Gongfa(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '无名功法',
            level: (m['level'] ?? 1) is num ? (m['level'] as num).toInt() : 1,
            type: GongfaType
                .values[(typeIdx).clamp(0, GongfaType.values.length - 1)],
            description: m['description']?.toString() ?? '',
            atkBoost: (m['atkBoost'] ?? 0) is num
                ? (m['atkBoost'] as num).toInt()
                : 0,
            defBoost: (m['defBoost'] ?? 0) is num
                ? (m['defBoost'] as num).toInt()
                : 0,
            hpBoost: (m['hpBoost'] ?? 0) is num
                ? (m['hpBoost'] as num).toInt()
                : 0,
            iconPath: m['iconPath']?.toString() ?? '',
            isLearned: (m['isLearned'] ?? false) == true,
            acquiredAt: at,
            count:
            (m['count'] ?? 1) is num ? (m['count'] as num).toInt() : 1,
            moveSpeedBoost:
            (m['moveSpeedBoost'] ?? 0.0 is num ? m['moveSpeedBoost'] : 0.0)
                .toDouble(),
          );
          parsedTechniques.add(g);
        }
        // 聚合出 map 备用
        for (final g in parsedTechniques) {
          final k = g.type.name;
          (parsedMap[k] ??= <String>[]).add(g.id);
        }
      } else if (rawTech.isNotEmpty && rawTech.first is String) {
        // ✅ 老格式：仅ID → 默认归到 movement 槽
        parsedMap['movement'] = rawTech.whereType<String>().toList();
      }
    }

    return Character(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      career: json['career'],
      cultivation:
      BigInt.tryParse(json['cultivation'].toString()) ?? BigInt.zero,
      cultivationEfficiency:
      (json['cultivationEfficiency'] ?? 1.0).toDouble(),
      currentMapStage: json['currentMapStage'] ?? 1,
      aptitude: json['aptitude'] ?? 0,
      realmLevel: json['realmLevel'] ?? 0,
      moveSpeed: (json['moveSpeed'] ?? 200.0).toDouble(),
      moveSpeedBoost: (json['moveSpeedBoost'] ?? 0.0).toDouble(),
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
      elements: elements,
      techniques: parsedTechniques,
      techniquesMap: parsedMap,
      createdAt:
      json['createdAt'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
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
    moveSpeedBoost: 0.0,
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
    elements: const {'gold': 0, 'wood': 0, 'water': 0, 'fire': 0, 'earth': 0},
    techniques: const <Gongfa>[],
    techniquesMap: const <String, List<String>>{},
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
