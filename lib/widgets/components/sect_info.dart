class SectInfo {
  final int id;        // 唯一ID
  final String name;   // 宗门名字
  final int level;     // 宗门等级
  final String description; // 宗门描述

  const SectInfo({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
  });

  /// 🌟 30个宗门，等级1~30
  static const List<SectInfo> allSects = [
    SectInfo(id: 1, name: '天雷宗', level: 1, description: '掌控雷霆之力，震慑八荒。'),
    SectInfo(id: 2, name: '万剑宗', level: 2, description: '万剑齐出，剑破苍穹。'),
    SectInfo(id: 3, name: '太虚宗', level: 3, description: '太虚幻境，变化无穷。'),
    SectInfo(id: 4, name: '青云宗', level: 4, description: '御剑青云，独步高空。'),
    SectInfo(id: 5, name: '焚天谷', level: 5, description: '焚尽天穹，烈焰滔天。'),
    SectInfo(id: 6, name: '金乌殿', level: 6, description: '金乌横空，烈日灼世。'),
    SectInfo(id: 7, name: '幽冥殿', level: 7, description: '幽冥之地，亡魂归宿。'),
    SectInfo(id: 8, name: '紫霄宫', level: 8, description: '紫气东来，霄汉无极。'),
    SectInfo(id: 9, name: '昆仑宗', level: 9, description: '昆仑仙境，福泽万世。'),
    SectInfo(id:10, name: '星辰殿', level:10, description: '星河璀璨，镇压四方。'),
    SectInfo(id:11, name: '无极宗', level:11, description: '无极大道，包罗万象。'),
    SectInfo(id:12, name: '赤炎宗', level:12, description: '赤焰滔天，焚化诸邪。'),
    SectInfo(id:13, name: '苍穹宗', level:13, description: '苍穹浩渺，气吞寰宇。'),
    SectInfo(id:14, name: '玄冥殿', level:14, description: '玄冥寒气，冰封天地。'),
    SectInfo(id:15, name: '琉璃宫', level:15, description: '琉璃无暇，映照心境。'),
    SectInfo(id:16, name: '剑冢宗', level:16, description: '万剑冢立，剑意无双。'),
    SectInfo(id:17, name: '幻月宗', level:17, description: '幻月迷影，心神莫测。'),
    SectInfo(id:18, name: '碧落宗', level:18, description: '碧落九天，仙凡无隔。'),
    SectInfo(id:19, name: '风雷谷', level:19, description: '风雷激荡，威震八方。'),
    SectInfo(id:20, name: '紫电宗', level:20, description: '紫电千里，破空追魂。'),
    SectInfo(id:21, name: '金鳞殿', level:21, description: '金鳞现世，化龙登天。'),
    SectInfo(id:22, name: '云渺宗', level:22, description: '云海渺渺，来去无踪。'),
    SectInfo(id:23, name: '千机阁', level:23, description: '机关算尽，智计无双。'),
    SectInfo(id:24, name: '落星宗', level:24, description: '星落如雨，镇灭万敌。'),
    SectInfo(id:25, name: '雪月谷', level:25, description: '雪月无痕，寒意入骨。'),
    SectInfo(id:26, name: '荒古宗', level:26, description: '荒古遗脉，万古独尊。'),
    SectInfo(id:27, name: '御灵殿', level:27, description: '御灵万兽，驱使山河。'),
    SectInfo(id:28, name: '冥河宗', level:28, description: '冥河滔滔，葬尽英魂。'),
    SectInfo(id:29, name: '焚天殿', level:29, description: '焚天烈焰，无物不焚。'),
    SectInfo(id:30, name: '不灭宗', level:30, description: '不灭之道，永恒不朽。'),
  ];
}
