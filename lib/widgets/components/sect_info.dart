import 'dart:math';

class SectInfo {
  final int id;               // 唯一ID
  final String name;          // 宗门名字
  final int level;            // 宗门等级
  final String description;   // 宗门描述
  final String masterName;    // 宗主名字

  final int masterPower;      // 宗主战力
  final int discipleCount;    // 弟子人数
  final int disciplePower;    // 单个弟子战力
  final BigInt spiritStoneLow; // 下品灵石数量

  const SectInfo({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.masterName,
    required this.masterPower,
    required this.discipleCount,
    required this.disciplePower,
    required this.spiritStoneLow,
  });

  /// 🌟 统一生成逻辑
  static SectInfo _generateSect(int id, int level) {
    final basePower = (1000 + pow((id - 1).toDouble(), 1.8) * 400).round();
    final baseDiscipleCount = (150 * pow(1.03, id - 1)).round();

    final masterPower = (basePower * pow(1.3, level)).round();
    final disciplePowerRatio = 0.08 + ((id - 1) * 0.003);
    final disciplePower = (masterPower * disciplePowerRatio).round();
    final discipleCount = (baseDiscipleCount * pow(1.1, level)).round();
    final spiritStoneLow = BigInt.from(masterPower * 5);

    return SectInfo(
      id: id,
      name: _names[id - 1],
      level: level,
      description: _descriptions[id - 1],
      masterName: _masters[id - 1],
      masterPower: masterPower,
      discipleCount: discipleCount,
      disciplePower: disciplePower,
      spiritStoneLow: spiritStoneLow,
    );
  }

  /// 🌟 一次性生成所有宗门
  static List<SectInfo> allSects = List.generate(30, (i) {
    final id = i + 1;
    return _generateSect(id, 1);
  });

  /// 🌟 工厂方法：根据id + level生成
  factory SectInfo.withLevel({
    required int id,
    required int level,
  }) {
    return _generateSect(id, level);
  }

  SectInfo copyWith({
    int? level,
    int? masterPower,
    int? discipleCount,
    int? disciplePower,
    BigInt? spiritStoneLow,
  }) {
    return SectInfo(
      id: id,
      name: name,
      level: level ?? this.level,
      description: description,
      masterName: masterName,
      masterPower: masterPower ?? this.masterPower,
      discipleCount: discipleCount ?? this.discipleCount,
      disciplePower: disciplePower ?? this.disciplePower,
      spiritStoneLow: spiritStoneLow ?? this.spiritStoneLow,
    );
  }

  // 宗门名字
  static const List<String> _names = [
    '天雷宗','万剑宗','太虚宗','青云宗','焚天谷','金乌殿','幽冥殿','紫霄宫','昆仑宗','星辰殿',
    '无极宗','赤炎宗','苍穹宗','玄冥殿','琉璃宫','剑冢宗','幻月宗','碧落宗','风雷谷','紫电宗',
    '金鳞殿','云渺宗','千机阁','落星宗','雪月谷','荒古宗','御灵殿','冥河宗','焚天殿','不灭宗'
  ];

  // 宗门描述
  static const List<String> _descriptions = [
    '掌控雷霆之力，震慑八荒。','万剑齐出，剑破苍穹。','太虚幻境，变化无穷。','御剑青云，独步高空。',
    '焚尽天穹，烈焰滔天。','金乌横空，烈日灼世。','幽冥之地，亡魂归宿。','紫气东来，霄汉无极。',
    '昆仑仙境，福泽万世。','星河璀璨，镇压四方。','无极大道，包罗万象。','赤焰滔天，焚化诸邪。',
    '苍穹浩渺，气吞寰宇。','玄冥寒气，冰封天地。','琉璃无暇，映照心境。','万剑冢立，剑意无双。',
    '幻月迷影，心神莫测。','碧落九天，仙凡无隔。','风雷激荡，威震八方。','紫电千里，破空追魂。',
    '金鳞现世，化龙登天。','云海渺渺，来去无踪。','机关算尽，智计无双。','星落如雨，镇灭万敌。',
    '雪月无痕，寒意入骨。','荒古遗脉，万古独尊。','御灵万兽，驱使山河。','冥河滔滔，葬尽英魂。',
    '焚天烈焰，无物不焚。','不灭之道，永恒不朽。'
  ];

  // 宗主名字
  static const List<String> _masters = [
    '苏青璃','白瑶芸','林梦溪','叶初晴','姜婉瑜','华凝霜','洛冰璃','苏绾烟','沈芷兰','慕容雪',
    '云轻舞','秦思婉','陆星澜','纪冷月','花君瑶','商玉璃','楚如烟','柳婉青','顾凌音','赵清竹',
    '闻人姝','江晚晴','唐语微','容初岚','凌清欢','姚宛溪','欧阳蓉','南宫瑾','孟婉兮','夏紫凝'
  ];
}
