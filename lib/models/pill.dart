import 'package:hive/hive.dart';

part 'pill.g.dart'; // 记得运行 build_runner 生成

/// 丹药类型（攻击、防御、血气）
@HiveType(typeId: 10) // 💡 枚举类型通常给大点的编号，避免和类冲突
enum PillType {
  @HiveField(0)
  attack,

  @HiveField(1)
  defense,

  @HiveField(2)
  health,
}

/// 单颗丹药的数据模型（支持堆叠）
@HiveType(typeId: 2) // ⚡ 用2，不要跟Weapon的1冲突
class Pill extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int level;

  @HiveField(2)
  PillType type;

  @HiveField(3)
  int count; // 当前数量（支持堆叠）

  @HiveField(4)
  int bonusAmount; // 增加的属性值（攻击、防御、血量之一）

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String iconPath; // 图标路径

  Pill({
    required this.name,
    required this.level,
    required this.type,
    required this.count,
    required this.bonusAmount,
    required this.createdAt,
    required this.iconPath,
  });
}
