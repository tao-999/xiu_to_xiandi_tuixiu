class Disciple {
  final String id; // ✅ 弟子唯一标识符
  final String name; // ✅ 弟子姓名
  final String gender; // ✅ 性别（"男" / "女"）
  final int age; // ✅ 年龄
  final int aptitude; // ✅ 资质（1~200）
  final String realm; // ✅ 当前境界（如“筑基期”、“金丹期”等）
  final int loyalty; // ✅ 忠诚度
  final String specialty; // ✅ 擅长类型（如“炼丹”、“战斗”、“管理”）
  final List<String> talents; // ✅ 天赋标签
  final int lifespan; // ✅ 剩余寿元
  final int cultivation; // ✅ 当前修为值

  final int breakthroughChance; // ✅ 当前突破成功率
  final List<String> skills; // ✅ 掌握的技能名称
  final int fatigue; // ✅ 疲劳值
  final bool isOnMission; // ✅ 是否执行任务中
  final int? missionEndTimestamp; // ✅ 任务结束时间戳

  /// ✅ 指定 imagePath 手动由外部传入（使用外部立绘资源）
  final String imagePath; // ✅ 弟子立绘图片路径

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
    required this.imagePath,
  });

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
      'imagePath': imagePath,
    };
  }

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
      talents: [...(map['talents'] ?? <String>[])],
      lifespan: map['lifespan'],
      cultivation: map['cultivation'],
      breakthroughChance: map['breakthroughChance'],
      skills: [...(map['skills'] ?? <String>[])],
      fatigue: map['fatigue'],
      isOnMission: map['isOnMission'],
      missionEndTimestamp: map['missionEndTimestamp'],
      imagePath: map['imagePath'] ?? '',
    );
  }
}
