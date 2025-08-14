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

  /// 🔫 激光（Laser Beam）
  static const AttackGongfaTemplate laserBeam = AttackGongfaTemplate(
    name: '激光',
    description: '汇聚灵能成束，一线贯穿，所指无不破。',
    atkBoost: 1.18, // 介于火球与雷链之间；DPS 在适配器里再乘系数
    iconPath: 'gongfa/laser_beam.png',
    palette: [
      Color(0xFFFFFFFF), // 核心纯白（极高亮）
      Color(0xFFFFE082), // 淡金辉光（热量外散）
      Color(0xFFFF7043), // 明亮橙红（火焰边缘）
      Color(0xFFFF1744), // 鲜红主色（主要光束色）
      Color(0xFFD50000), // 深红外晕（渐变到黑）
    ],
  );

  static const List<AttackGongfaTemplate> all = [
    fireball,
    chainLightning,
    laserBeam, // ✅ 用激光替换原来的流星坠
  ];

  static AttackGongfaTemplate? byName(String name) {
    for (final e in all) {
      if (e.name == name) return e;
    }
    return null;
  }
}
