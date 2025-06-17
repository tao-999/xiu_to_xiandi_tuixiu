import 'package:hive/hive.dart';

part 'weapon.g.dart'; // Hive 自动生成的文件

@HiveType(typeId: 7) // 确保这个 typeId 没和其他模型重复
class Weapon extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int level;

  @HiveField(2)
  String type; // BlueprintType.name，例如 'weapon'、'armor'、'seal'

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int attackBoost;

  @HiveField(5)
  int defenseBoost;

  @HiveField(6)
  int hpBoost;

  @HiveField(7)
  List<String> specialEffects;

  Weapon({
    required this.name,
    required this.level,
    required this.type,
    required this.createdAt,
    this.attackBoost = 0,
    this.defenseBoost = 0,
    this.hpBoost = 0,
    this.specialEffects = const [],
  });
}
