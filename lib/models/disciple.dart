// lib/models/disciple.dart

import 'package:hive/hive.dart';

part 'disciple.g.dart'; // 自动生成文件

@HiveType(typeId: 1)
class Disciple extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String gender;

  @HiveField(3)
  int age;

  @HiveField(4)
  int aptitude;

  @HiveField(5)
  int hp;

  @HiveField(6)
  int atk;

  @HiveField(7)
  int def;

  @HiveField(8)
  String realm;

  @HiveField(9)
  int loyalty;

  @HiveField(10)
  String specialty;

  @HiveField(11)
  List<String> talents;

  @HiveField(12)
  int lifespan;

  @HiveField(13)
  int cultivation;

  @HiveField(14)
  int breakthroughChance;

  @HiveField(15)
  List<String> skills;

  @HiveField(16)
  int fatigue;

  @HiveField(17)
  bool isOnMission;

  @HiveField(18)
  int? missionEndTimestamp;

  @HiveField(19)
  String imagePath;

  @HiveField(20)
  int? joinedAt;

  @HiveField(21)
  String? assignedRoom;

  Disciple({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.aptitude,
    required this.hp,
    required this.atk,
    required this.def,
    this.realm = '',
    this.loyalty = 100,
    this.specialty = '',
    this.talents = const [],
    this.lifespan = 0,
    this.cultivation = 0,
    this.breakthroughChance = 0,
    this.skills = const [],
    this.fatigue = 0,
    this.isOnMission = false,
    this.missionEndTimestamp,
    this.imagePath = '',
    this.joinedAt,
    this.assignedRoom,
  });

  Disciple copyWith({
    int? age,
    int? joinedAt,
    String? assignedRoom,
  }) {
    return Disciple(
      id: id,
      name: name,
      gender: gender,
      age: age ?? this.age,
      aptitude: aptitude,
      hp: hp,
      atk: atk,
      def: def,
      realm: realm,
      loyalty: loyalty,
      specialty: specialty,
      talents: talents,
      lifespan: lifespan,
      cultivation: cultivation,
      breakthroughChance: breakthroughChance,
      skills: skills,
      fatigue: fatigue,
      isOnMission: isOnMission,
      missionEndTimestamp: missionEndTimestamp,
      imagePath: imagePath,
      joinedAt: joinedAt ?? this.joinedAt,
      assignedRoom: assignedRoom,
    );
  }
}
