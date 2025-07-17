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
  int loyalty;

  @HiveField(9)
  String specialty;

  @HiveField(10)
  List<String> talents;

  @HiveField(11)
  int lifespan;

  @HiveField(12)
  int cultivation;

  @HiveField(13)
  int breakthroughChance;

  @HiveField(14)
  List<String> skills;

  @HiveField(15)
  int fatigue;

  @HiveField(16)
  bool isOnMission;

  @HiveField(17)
  int? missionEndTimestamp;

  @HiveField(18)
  String imagePath;

  @HiveField(19)
  int? joinedAt;

  @HiveField(20)
  String? assignedRoom;

  @HiveField(21)
  String description;

  @HiveField(22)
  int favorability;

  @HiveField(23)
  String? role;

  // ✅ 新增百分比加成字段
  @HiveField(24)
  double extraHp;

  @HiveField(25)
  double extraAtk;

  @HiveField(26)
  double extraDef;

  // ✅ 新增修为层数（默认0）
  @HiveField(27)
  int realmLevel;

  Disciple({
    this.id = '',
    this.name = '',
    this.gender = '',
    this.age = 0,
    this.aptitude = 0,
    this.hp = 0,
    this.atk = 0,
    this.def = 0,
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
    this.extraHp = 0.0,
    this.extraAtk = 0.0,
    this.extraDef = 0.0,
    this.realmLevel = 0,
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
    double? extraHp,
    double? extraAtk,
    double? extraDef,
    int? realmLevel,
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
      extraHp: extraHp ?? this.extraHp,
      extraAtk: extraAtk ?? this.extraAtk,
      extraDef: extraDef ?? this.extraDef,
      realmLevel: realmLevel ?? this.realmLevel,
    );
  }
}
