final List<Map<String, dynamic>> xianrenFemaleData = List.generate(30, (index) {
  final int number = index + 1;
  final List<String> names = [
    '凌霄仙子',
    '云梦仙姝',
    '碧落仙姬',
    '紫霄仙婵',
    '玄月仙颜',
    '雪羽仙萝',
    '琉璃仙珑',
    '青萝仙珮',
    '瑶光仙妍',
    '灵犀仙芸',
    '星阙仙绫',
    '素心仙蔓',
    '冷霜仙嫣',
    '幽兰仙语',
    '澹台仙瑾',
    '玉衡仙曦',
    '暮雪仙岚',
    '绮夜仙卿',
    '流云仙霓',
    '飞霞仙筠',
    '烟萝仙娆',
    '凌波仙珂',
    '月影仙璃',
    '听雪仙萝',
    '千秋仙枫',
    '落霞仙琦',
    '浮光仙韵',
    '白露仙苓',
    '宛若仙悠',
    '青鸾仙绣',
  ];

  final List<String> descriptions = [
    '自幼通灵，掌握万兽之心，曾一笑令群兽俯首。',
    '曾于星渊中沉睡百年，醒来时已是传说。',
    '修行于碧落仙池，善御水灵之术。',
    '紫霄神雷加身，行走凡间如梦似幻。',
    '玄月初照，面容永不老去。',
    '雪域孤峰长居千载，无人能窥其真颜。',
    '琉璃心生，心念即化神光。',
    '青萝幽谷独居，不染世尘。',
    '瑶池仙露滋养，肤胜白雪。',
    '灵犀一指，可破万法结界。',
    '星阙之下应劫重生，半人半仙。',
    '素心无尘，言出即道。',
    '冷霜覆面，唯独红唇留人间痕迹。',
    '幽兰暗香，引魂入梦。',
    '澹台氏后人，承千古剑道传承。',
    '玉衡星辉入骨，夜中自明。',
    '暮雪千里，唯她一人白衣立雪中。',
    '绮夜长歌，迷离世人心魄。',
    '流云飞袖，瞬息可越山河。',
    '飞霞踏空而舞，红影不留凡尘。',
    '烟萝绕身，似真似幻。',
    '凌波微步，无迹可寻。',
    '月影相随，素衣独行。',
    '听雪而眠，一梦十年。',
    '千秋一剑，斩断恩怨情仇。',
    '落霞映面，唯余寂寥。',
    '浮光掠影，笑看盛世烟火。',
    '白露初凝，泪染青衣。',
    '宛若春风，拂去心头尘埃。',
    '青鸾伴生，命定孤高。',
  ];

  final String name = names[index];
  final String description = descriptions[index];
  const int aptitude = 101;

  return {
    'name': name,
    'gender': 'female',
    'aptitude': aptitude,
    'hp': 100 + (aptitude - 31), //170
    'atk': 20 + (aptitude - 31), //90
    'def': 10 + (aptitude - 31), //80
    'age': 0,
    'imagePath': 'assets/images/xianren/$number.png',
    'thumbnailPath': 'assets/images/xianren_icon/$number.png',
    'description': description,
  };
});
