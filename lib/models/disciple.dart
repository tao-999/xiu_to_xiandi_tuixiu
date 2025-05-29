class Disciple {
  final String id;
  final String name;
  final String gender;
  final int age;
  final int aptitude;
  final String realm;
  final int loyalty;
  final String specialty;
  final List<String> talents;
  final int lifespan;
  final int cultivation;

  // 后期系统字段
  final int breakthroughChance;
  final List<String> skills;
  final int fatigue;
  final bool isOnMission;
  final int? missionEndTimestamp;

  Disciple({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.aptitude,
    required this.realm,
    required this.loyalty,
    required this.specialty,
    required this.talents,
    required this.lifespan,
    required this.cultivation,
    required this.breakthroughChance,
    required this.skills,
    required this.fatigue,
    required this.isOnMission,
    required this.missionEndTimestamp,
  });

  /// ✅ 存储序列化
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'aptitude': aptitude,
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
    };
  }

  /// ✅ 反序列化
  factory Disciple.fromMap(Map<String, dynamic> map) {
    return Disciple(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      aptitude: map['aptitude'],
      realm: map['realm'],
      loyalty: map['loyalty'],
      specialty: map['specialty'],
      talents: [...(map['talents'] ?? <String>[])], // ✅ 强制复制
      lifespan: map['lifespan'],
      cultivation: map['cultivation'],
      breakthroughChance: map['breakthroughChance'],
      skills: [...(map['skills'] ?? <String>[])],   // ✅ 强制复制
      fatigue: map['fatigue'],
      isOnMission: map['isOnMission'],
      missionEndTimestamp: map['missionEndTimestamp'],
    );
  }
}
