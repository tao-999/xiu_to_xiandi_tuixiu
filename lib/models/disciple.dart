class Disciple {
  final String id; // ✅ 弟子唯一标识符
  final String name; // ✅ 弟子姓名
  final String gender; // ✅ 性别（"男" / "女"）
  final int age; // ✅ 年龄
  final int aptitude; // ✅ 资质（决定成长上限，通常 1~200）
  final String realm; // ✅ 当前境界（如“筑基期”、“金丹期”等）
  final int loyalty; // ✅ 忠诚度（0~100，影响叛变、任务完成度等）
  final String specialty; // ✅ 擅长类型（如“炼丹”、“战斗”、“管理”）
  final List<String> talents; // ✅ 天赋标签（如“灵体”、“慧根”）
  final int lifespan; // ✅ 剩余寿元（单位：年）
  final int cultivation; // ✅ 当前修为数值（决定突破可能）

  // ✅ 后期系统字段，用于任务、技能、状态管理
  final int breakthroughChance; // ✅ 当前突破成功率（0~100）
  final List<String> skills; // ✅ 掌握的技能名称列表
  final int fatigue; // ✅ 疲劳值（影响可否执行任务或战斗）
  final bool isOnMission; // ✅ 是否正在执行外派任务
  final int? missionEndTimestamp; // ✅ 当前任务结束时间戳（ms），为空表示未出征

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

  /// ✅ 序列化为 Map（用于存储，如 Hive/JSON）
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

  /// ✅ 从 Map 反序列化为 Disciple 实例（用于读取保存的数据）
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
      talents: [...(map['talents'] ?? <String>[])], // ✅ 防止共享引用
      lifespan: map['lifespan'],
      cultivation: map['cultivation'],
      breakthroughChance: map['breakthroughChance'],
      skills: [...(map['skills'] ?? <String>[])],   // ✅ 防止共享引用
      fatigue: map['fatigue'],
      isOnMission: map['isOnMission'],
      missionEndTimestamp: map['missionEndTimestamp'],
    );
  }
}
