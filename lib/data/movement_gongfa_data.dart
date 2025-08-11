// 📂 lib/data/movement_gongfa_data.dart
import 'package:flutter/material.dart';
import '../models/gongfa.dart';

/// 速度系功法【模板】
/// 只保留掉落/展示会用到的字段：name / description / moveSpeedBoost / iconPath / type / palette
class MovementGongfaTemplate {
  final String name;
  final String description;
  final double moveSpeedBoost; // 基础百分比加成
  final String iconPath;       // 不含 'assets/images/' 前缀
  final GongfaType type;       // 恒为 movement
  final List<Color> palette;   // 🎨 用于 AirFlowEffect 的颜色序列（3~7 个）

  const MovementGongfaTemplate({
    required this.name,
    required this.description,
    required this.moveSpeedBoost,
    required this.iconPath,
    required this.palette,
    this.type = GongfaType.movement,
  });
}

class MovementGongfaData {
  /// 全部速度功法模板
  static final List<MovementGongfaTemplate> all = const [
    MovementGongfaTemplate(
      name: '瞬狱千影步',
      description: '一步千影，影随心灭。',
      moveSpeedBoost: 0.35,
      iconPath: 'gongfa/1.png',
      palette: [
        Color(0xFFEDE7F6), Color(0xFFD1C4E9), Color(0xFF9575CD),
        Color(0xFF7E57C2), Color(0xFF5E35B1),
      ],
    ),
    MovementGongfaTemplate(
      name: '裂风追月诀',
      description: '裂风破夜，追月无痕。',
      moveSpeedBoost: 0.28,
      iconPath: 'gongfa/2.png',
      palette: [
        Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF26C6DA),
        Color(0xFF00ACC1),
      ],
    ),
    MovementGongfaTemplate(
      name: '雷痕换日法',
      description: '雷走九霄，朝暮可换。',
      moveSpeedBoost: 0.32,
      iconPath: 'gongfa/3.png',
      palette: [
        Color(0xFFFFF59D), Color(0xFFFFEE58), Color(0xFF42A5F5),
        Color(0xFF1E88E5),
      ],
    ),
    MovementGongfaTemplate(
      name: '流光掠星身',
      description: '身化流光，掠星如拾。',
      moveSpeedBoost: 0.30,
      iconPath: 'gongfa/4.png',
      palette: [
        Color(0xFFFF8A80), Color(0xFFFF5252), Color(0xFF7C4DFF),
        Color(0xFF536DFE),
      ],
    ),
    MovementGongfaTemplate(
      name: '星河缩地经',
      description: '缩地千里，踏河成桥。',
      moveSpeedBoost: 0.40,
      iconPath: 'gongfa/5.png',
      palette: [
        Color(0xFFB3E5FC), Color(0xFF64B5F6), Color(0xFF3949AB),
        Color(0xFF283593),
      ],
    ),
    MovementGongfaTemplate(
      name: '疾魄踏虚诀',
      description: '虚空作阶，魄破风吼。',
      moveSpeedBoost: 0.33,
      iconPath: 'gongfa/6.png',
      palette: [
        Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF66BB6A),
        Color(0xFF26A69A),
      ],
    ),
    MovementGongfaTemplate(
      name: '飒雪凌霄步',
      description: '雪意三尺，凌霄无轨。',
      moveSpeedBoost: 0.26,
      iconPath: 'gongfa/7.png',
      palette: [
        Color(0xFFFFFFFF), Color(0xFFE3F2FD), Color(0xFF90CAF9),
        Color(0xFFB2EBF2),
      ],
    ),
    MovementGongfaTemplate(
      name: '九转风神罡',
      description: '九转化罡，风随神行。',
      moveSpeedBoost: 0.38,
      iconPath: 'gongfa/8.png',
      palette: [
        Color(0xFFE6EE9C), Color(0xFFCDDC39), Color(0xFF8BC34A),
        Color(0xFF4CAF50),
      ],
    ),
    MovementGongfaTemplate(
      name: '破晓瞬移篇',
      description: '破晓即至，影不及身。',
      moveSpeedBoost: 0.42,
      iconPath: 'gongfa/9.png',
      palette: [
        Color(0xFFFFF8E1), Color(0xFFFFE082), Color(0xFFFFB74D),
        Color(0xFFFF8A65),
      ],
    ),
    MovementGongfaTemplate(
      name: '影遁无相道',
      description: '无相无踪，影遁千界。',
      moveSpeedBoost: 0.29,
      iconPath: 'gongfa/10.png',
      palette: [
        Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFF616161),
        Color(0xFF424242),
      ],
    ),
  ];

  // 可选工具
  static MovementGongfaTemplate? byName(String name) {
    try { return all.firstWhere((e) => e.name == name); } catch (_) { return null; }
  }
  static MovementGongfaTemplate? topSpeed() {
    if (all.isEmpty) return null;
    MovementGongfaTemplate best = all.first;
    for (final e in all.skip(1)) {
      if (e.moveSpeedBoost > best.moveSpeedBoost) best = e;
    }
    return best;
  }
}
