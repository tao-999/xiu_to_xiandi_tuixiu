class BeibaoResource {
  final String name;
  final String field; // ✅ 资源在 Resources 中的字段名
  final String imagePath;
  final String description;

  const BeibaoResource({
    required this.name,
    required this.field,
    required this.imagePath,
    required this.description,
  });
}

final List<BeibaoResource> beibaoResourceList = [
  BeibaoResource(
    name: '下品灵石',
    field: 'spiritStoneLow',
    imagePath: 'assets/images/spirit_stone_low.png',
    description: '修炼入门的基础灵石，常用于突破练气期。',
  ),
  BeibaoResource(
    name: '中品灵石',
    field: 'spiritStoneMid',
    imagePath: 'assets/images/spirit_stone_mid.png',
    description: '较为常见的灵石，修炼进阶期的重要资源。',
  ),
  BeibaoResource(
    name: '上品灵石',
    field: 'spiritStoneHigh',
    imagePath: 'assets/images/spirit_stone_high.png',
    description: '品质极佳，可用于筑基、金丹等高阶修炼。',
  ),
  BeibaoResource(
    name: '极品灵石',
    field: 'spiritStoneSupreme',
    imagePath: 'assets/images/spirit_stone_supreme.png',
    description: '罕见至极，蕴含浓郁灵气，可供元婴及以上修士使用。',
  ),
  BeibaoResource(
    name: '招募券',
    field: 'recruitTicket',
    imagePath: 'assets/images/recruit_ticket.png',
    description: '可用于招募弟子，增加宗门实力。',
  ),
  BeibaoResource(
    name: '资质提升券',
    field: 'fateRecruitCharm',
    imagePath: 'assets/images/fate_recruit_charm.png',
    description: '触发特殊剧情，结识独特弟子。',
  ),
];
