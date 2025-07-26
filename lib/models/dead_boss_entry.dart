import 'package:hive/hive.dart';
import 'package:flame/components.dart';

part 'dead_boss_entry.g.dart';

@HiveType(typeId: 17)
class DeadBossEntry {
  @HiveField(0)
  final String tileKey;

  @HiveField(1)
  final double x;

  @HiveField(2)
  final double y;

  @HiveField(3)
  final String bossType;

  @HiveField(4)
  final double width;

  @HiveField(5)
  final double height;

  DeadBossEntry({
    required this.tileKey,
    required this.x,
    required this.y,
    required this.bossType,
    required this.width,
    required this.height,
  });

  Vector2 get position => Vector2(x, y);
  Vector2 get size => Vector2(width, height);
}
