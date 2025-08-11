// 📂 lib/data/attack_gongfa_data.dart
import 'package:flutter/material.dart';
import '../models/gongfa.dart';

/// 攻击系功法【模板】
/// 只保留掉落/展示会用到的字段：name / description / atkBoost / iconPath / type / palette
class AttackGongfaTemplate {
  final String name;
  final String description;
  final double atkBoost;   // 百分比加成：0.10 = +10%
  final String iconPath;   // 不含 'assets/images/' 前缀
  final GongfaType type;   // 恒为 attack
  final List<Color> palette; // 可用于攻击特效的配色（3~7个）

  const AttackGongfaTemplate({
    required this.name,
    required this.description,
    required this.atkBoost,
    required this.iconPath,
    required this.palette,
    this.type = GongfaType.attack,
  });
}

class AttackGongfaData {
  /// 目前只需要一个：火球术
  static const AttackGongfaTemplate fireball = AttackGongfaTemplate(
    name: '火球术',
    description: '凝聚灵炎，化球疾射，所至之处烈焰滔天。',
    atkBoost: 1.10,
    iconPath: 'gongfa/fireball.png',
    palette: [
      Color(0xFFFFF3E0), // 柔光
      Color(0xFFFFE082), // 金黄
      Color(0xFFFFB74D), // 炽橙
      Color(0xFFFF7043), // 火红
      Color(0xFFEF5350), // 深红
    ],
  );

  static const List<AttackGongfaTemplate> all = [fireball];

  static AttackGongfaTemplate? byName(String name) {
    for (final e in all) {
      if (e.name == name) return e;
    }
    return null;
  }
}
