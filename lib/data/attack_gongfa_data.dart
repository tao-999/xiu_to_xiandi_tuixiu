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
  /// 🔥 火球术
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

  /// ⚡ 雷链（Chain Lightning）
  static const AttackGongfaTemplate chainLightning = AttackGongfaTemplate(
    name: '雷链',
    description: '以真雷为引，电光连环跃迁，群敌顷刻焦黑。',
    atkBoost: 1.20, // 多跳技能，实战更强
    iconPath: 'gongfa/chain_lightning.png',
    palette: [
      Color(0xFFFFFFFF), // 核心高光
      Color(0xFFE3F2FD), // 淡蓝辉光
      Color(0xFF80DEEA), // 青蓝
      Color(0xFF00B0FF), // 电蓝
      Color(0xFF2979FF), // 深电蓝
      Color(0xFF7C4DFF), // 紫电边缘
    ],
  );

  /// ☄️ 流星坠（Meteor Rain）
  static const AttackGongfaTemplate meteorRain = AttackGongfaTemplate(
    name: '流星坠',
    description: '引星坠地，烈焰轰鸣，冲击波席卷四野。',
    atkBoost: 1.15, // 范围AoE，介于火球与雷链之间
    iconPath: 'gongfa/meteor_rain.png',
    palette: [
      Color(0xFFFFFDE7), // 微黄高光
      Color(0xFFFFE082), // 金黄
      Color(0xFFFFB74D), // 橙火
      Color(0xFFFF8A65), // 橙红
      Color(0xFF8D6E63), // 烟尘棕
    ],
  );

  static const List<AttackGongfaTemplate> all = [
    fireball,
    chainLightning,
    meteorRain, // 👈 新增
  ];

  static AttackGongfaTemplate? byName(String name) {
    for (final e in all) {
      if (e.name == name) return e;
    }
    return null;
  }
}
