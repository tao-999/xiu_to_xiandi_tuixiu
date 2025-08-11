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

  /// 攻击加成（小数；1.10=110% 伤害，或 0.10=+10% 视你的语义）
  @HiveField(5)
  final double atkBoost;

  /// 防御加成（小数；0.15 = +15%）
  @HiveField(6)
  final double defBoost;

  /// 气血加成（小数；0.20 = +20%）
  @HiveField(7)
  final double hpBoost;

  @HiveField(8)
  final String iconPath;

  @HiveField(9)
  bool isLearned;

  @HiveField(10)
  final DateTime acquiredAt;

  @HiveField(11)
  int count; // 拥有数量（默认为1）

  /// 移动速度加成（小数；0.25 = +25%）
  @HiveField(12)
  final double moveSpeedBoost;

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
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  /// ✅ 拷贝（更新数量/学习状态/加成等）
  Gongfa copyWith({
    int? count,
    bool? isLearned,
    double? speedBoost,
    double? atkBoost,
    double? defBoost,
    double? hpBoost,
  }) {
    return Gongfa(
      id: id,
      name: name,
      level: level,
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
