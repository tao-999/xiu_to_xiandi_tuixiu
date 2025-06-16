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
    description: '灵气稀薄，聊胜于无，勉强够你打坐两炷香。',
  ),
  BeibaoResource(
    name: '中品灵石',
    field: 'spiritStoneMid',
    imagePath: 'assets/images/spirit_stone_mid.png',
    description: '寻常修士最爱，不贵还顶用，拿来修炼刚刚好。',
  ),
  BeibaoResource(
    name: '上品灵石',
    field: 'spiritStoneHigh',
    imagePath: 'assets/images/spirit_stone_high.png',
    description: '灵气浓郁，堪比修仙界“硬通货”，出门都不敢露太多。',
  ),
  BeibaoResource(
    name: '极品灵石',
    field: 'spiritStoneSupreme',
    imagePath: 'assets/images/spirit_stone_supreme.png',
    description: '传说元婴老怪都抢着用，一块能换一座小宗门。',
  ),
  BeibaoResource(
    name: '招募券',
    field: 'recruitTicket',
    imagePath: 'assets/images/recruit_ticket.png',
    description: '听说丢出去就能招来俊男美女……但得看脸也看命。',
  ),
  BeibaoResource(
    name: '资质提升券',
    field: 'fateRecruitCharm',
    imagePath: 'assets/images/fate_recruit_charm.png',
    description: '点燃命运的火种，助你逆天改命，抱得天骄归。',
  ),
];
