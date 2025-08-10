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

  @HiveField(5)
  final int atkBoost;

  @HiveField(6)
  final int defBoost;

  @HiveField(7)
  final int hpBoost;

  @HiveField(8)
  final String iconPath;

  @HiveField(9)
  bool isLearned;

  @HiveField(10)
  final DateTime acquiredAt;

  @HiveField(11)
  int count; // 拥有数量（默认为1）

  @HiveField(12)
  final double moveSpeedBoost; // 🆕 移动速度平铺加成（可正可负）

  Gongfa({
    required this.id,
    required this.name,
    required this.level,
    required this.type,
    required this.description,
    this.atkBoost = 0,
    this.defBoost = 0,
    this.hpBoost = 0,
    this.iconPath = '',
    this.isLearned = false,
    DateTime? acquiredAt,
    this.count = 1,
    this.moveSpeedBoost = 0.0, // 🆕 默认0
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  /// ✅ 拷贝方法（用于更新数量、学习状态、速度加成等）
  Gongfa copyWith({
    int? count,
    bool? isLearned,
    double? speedBoost, // 🆕
  }) {
    return Gongfa(
      id: id,
      name: name,
      level: level,
      type: type,
      description: description,
      atkBoost: atkBoost,
      defBoost: defBoost,
      hpBoost: hpBoost,
      iconPath: iconPath,
      isLearned: isLearned ?? this.isLearned,
      acquiredAt: acquiredAt,
      count: count ?? this.count,
      moveSpeedBoost: speedBoost ?? this.moveSpeedBoost, // 🆕
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
