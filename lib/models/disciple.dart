class Disciple {
  final String id;
  final String name;
  final String gender;
  final int age;
  final int aptitude;
  final int hp;
  final int atk;
  final int def;
  final String realm;

  final int loyalty;
  final String specialty;
  final List<String> talents;
  final int lifespan;
  final int cultivation;
  final int breakthroughChance;
  final List<String> skills;
  final int fatigue;
  final bool isOnMission;
  final int? missionEndTimestamp;
  final String imagePath;

  final int? joinedAt;

  /// ✅ 新增：当前驻守房间（如 liandanfang、lianqifang 等）
  final String? assignedRoom;

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
    this.assignedRoom, // ✅ 新字段
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'aptitude': aptitude,
      'hp': hp,
      'atk': atk,
      'def': def,
      'realm': realm,
      'loyalty': loyalty,
      'specialty': specialty,
      'talents': talents,
      'lifespan': lifespan,
      'cultivation': cultivation,
      'breakthroughChance': breakthroughChance,
      'skills': skills,
      'fatigue': fatigue,
      'isOnMission': isOnMission,
      'missionEndTimestamp': missionEndTimestamp,
      'imagePath': imagePath,
      'joinedAt': joinedAt,
      'assignedRoom': assignedRoom, // ✅ 加入 map
    };
  }

  factory Disciple.fromMap(Map<String, dynamic> map) {
    return Disciple(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      aptitude: map['aptitude'],
      hp: map['hp'],
      atk: map['atk'],
      def: map['def'],
      realm: map['realm'],
      loyalty: map['loyalty'] ?? 100,
      specialty: map['specialty'] ?? '',
      talents: List<String>.from(map['talents'] ?? []),
      lifespan: map['lifespan'] ?? 0,
      cultivation: map['cultivation'] ?? 0,
      breakthroughChance: map['breakthroughChance'] ?? 0,
      skills: List<String>.from(map['skills'] ?? []),
      fatigue: map['fatigue'] ?? 0,
      isOnMission: map['isOnMission'] ?? false,
      missionEndTimestamp: map['missionEndTimestamp'],
      imagePath: map['imagePath'] ?? '',
      joinedAt: map['joinedAt'],
      assignedRoom: map['assignedRoom'], // ✅ 加入解析
    );
  }

  Disciple copyWith({
    int? age,
    int? joinedAt,
    String? assignedRoom, // ✅ 加回来了
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
      assignedRoom: assignedRoom, // ✅ 传啥用啥，null 就是清除
    );
  }
}
