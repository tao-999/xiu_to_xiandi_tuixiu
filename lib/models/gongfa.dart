// 📂 lib/models/gongfa.dart
import 'package:hive/hive.dart';

part 'gongfa.g.dart';

@HiveType(typeId: 14)
class Gongfa {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int level;

  @HiveField(3)
  final GongfaType type;

  @HiveField(4)
  final String description;

  /// 伤害加成（按你工程语义：1.10 = 110% 伤害；或 0.10 = +10%）
  @HiveField(5)
  final double atkBoost;

  /// 防御加成（0.15 = +15%）
  @HiveField(6)
  final double defBoost;

  /// 气血加成（0.20 = +20%）
  @HiveField(7)
  final double hpBoost;

  @HiveField(8)
  final String iconPath;

  @HiveField(9)
  bool isLearned;

  @HiveField(10)
  final DateTime acquiredAt;

  @HiveField(11)
  int count; // 拥有数量（默认 1）

  /// 移速加成（0.25 = +25%）
  @HiveField(12)
  final double moveSpeedBoost;

  /// ⚡ 攻速（Attacks Per Second，次/秒）
  /// 老数据没有这个字段时，使用构造默认值 1.0
  @HiveField(13)
  final double attackSpeed;

  Gongfa({
    required this.id,
    required this.name,
    required this.level,
    required this.type,
    required this.description,
    this.atkBoost = 0.0,
    this.defBoost = 0.0,
    this.hpBoost = 0.0,
    this.iconPath = '',
    this.isLearned = false,
    DateTime? acquiredAt,
    this.count = 1,
    this.moveSpeedBoost = 0.0,
    this.attackSpeed = 1.0, // ← 默认 1 次/秒，向后兼容
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  /// ✅ 拷贝（更新数量/学习状态/各加成/攻速）
  Gongfa copyWith({
    int? count,
    bool? isLearned,
    double? speedBoost,
    double? atkBoost,
    double? defBoost,
    double? hpBoost,
    double? attackSpeed,
    int? level, // ✅ 就补这个
  }) {
    return Gongfa(
      id: id,
      name: name,
      level: level ?? this.level,          // ✅ 关键：允许改等级
      type: type,
      description: description,
      atkBoost: atkBoost ?? this.atkBoost,
      defBoost: defBoost ?? this.defBoost,
      hpBoost: hpBoost ?? this.hpBoost,
      iconPath: iconPath,
      isLearned: isLearned ?? this.isLearned,
      acquiredAt: acquiredAt,
      count: count ?? this.count,
      moveSpeedBoost: speedBoost ?? moveSpeedBoost,
      attackSpeed: attackSpeed ?? this.attackSpeed,
    );
  }
}

@HiveType(typeId: 15)
enum GongfaType {
  @HiveField(0)
  attack,
  @HiveField(1)
  defense,
  @HiveField(2)
  movement,
  @HiveField(3)
  support,
  @HiveField(4)
  special,
  @HiveField(5)
  passive,
}
