// lib/models/disciples.dart

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

  @HiveField(22)
  String description;

  @HiveField(23)
  int favorability;

  @HiveField(24)
  String? role;

  Disciple({
    this.id = '',
    this.name = '',
    this.gender = '',
    this.age = 0,
    this.aptitude = 0,
    this.hp = 0,
    this.atk = 0,
    this.def = 0,
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
    this.description = '',
    this.favorability = 0,
    this.role = '弟子',
  });

  static const _unset = Object();

  Disciple copyWith({
    String? id,
    String? name,
    String? gender,
    int? age,
    int? aptitude,
    int? hp,
    int? atk,
    int? def,
    String? realm,
    int? loyalty,
    String? specialty,
    List<String>? talents,
    int? lifespan,
    int? cultivation,
    int? breakthroughChance,
    List<String>? skills,
    int? fatigue,
    bool? isOnMission,
    int? missionEndTimestamp,
    String? imagePath,
    int? joinedAt,
    Object? assignedRoom = _unset,
    String? description,
    int? favorability,
    String? role,
  }) {
    return Disciple(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      aptitude: aptitude ?? this.aptitude,
      hp: hp ?? this.hp,
      atk: atk ?? this.atk,
      def: def ?? this.def,
      realm: realm ?? this.realm,
      loyalty: loyalty ?? this.loyalty,
      specialty: specialty ?? this.specialty,
      talents: talents ?? this.talents,
      lifespan: lifespan ?? this.lifespan,
      cultivation: cultivation ?? this.cultivation,
      breakthroughChance: breakthroughChance ?? this.breakthroughChance,
      skills: skills ?? this.skills,
      fatigue: fatigue ?? this.fatigue,
      isOnMission: isOnMission ?? this.isOnMission,
      missionEndTimestamp: missionEndTimestamp ?? this.missionEndTimestamp,
      imagePath: imagePath ?? this.imagePath,
      joinedAt: joinedAt ?? this.joinedAt,
      assignedRoom: identical(assignedRoom, _unset)
          ? this.assignedRoom
          : assignedRoom as String?,
      description: description ?? this.description,
      favorability: favorability ?? this.favorability,
      role: role ?? this.role,
    );
  }
}
