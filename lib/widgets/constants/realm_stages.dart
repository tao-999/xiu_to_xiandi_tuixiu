class RealmStage {
  final String name;
  final String phase; // 阶段（练气、筑基...）
  final String subStage; // 子阶段（初期、中期、后期、九重等）
  final int requiredQi;
  final int totalAccumulatedQi;

  const RealmStage({
    required this.name,
    required this.phase,
    required this.subStage,
    required this.requiredQi,
    required this.totalAccumulatedQi,
  });
}

final List<RealmStage> realmStages = [
  // 练气期（九重）
  RealmStage(name: '练气一重', phase: '练气期', subStage: '一重', requiredQi: 100, totalAccumulatedQi: 100),
  RealmStage(name: '练气二重', phase: '练气期', subStage: '二重', requiredQi: 150, totalAccumulatedQi: 250),
  RealmStage(name: '练气三重', phase: '练气期', subStage: '三重', requiredQi: 250, totalAccumulatedQi: 500),
  RealmStage(name: '练气四重', phase: '练气期', subStage: '四重', requiredQi: 400, totalAccumulatedQi: 900),
  RealmStage(name: '练气五重', phase: '练气期', subStage: '五重', requiredQi: 650, totalAccumulatedQi: 1550),
  RealmStage(name: '练气六重', phase: '练气期', subStage: '六重', requiredQi: 1050, totalAccumulatedQi: 2600),
  RealmStage(name: '练气七重', phase: '练气期', subStage: '七重', requiredQi: 1700, totalAccumulatedQi: 4300),
  RealmStage(name: '练气八重', phase: '练气期', subStage: '八重', requiredQi: 2750, totalAccumulatedQi: 7050),
  RealmStage(name: '练气九重', phase: '练气期', subStage: '九重', requiredQi: 4450, totalAccumulatedQi: 11500),

  // 筑基 ~ 大乘：统一为初期、中期、后期
  RealmStage(name: '筑基初期', phase: '筑基期', subStage: '初期', requiredQi: 7200, totalAccumulatedQi: 18700),
  RealmStage(name: '筑基中期', phase: '筑基期', subStage: '中期', requiredQi: 11650, totalAccumulatedQi: 30350),
  RealmStage(name: '筑基后期', phase: '筑基期', subStage: '后期', requiredQi: 18850, totalAccumulatedQi: 49200),

  RealmStage(name: '金丹初期', phase: '金丹期', subStage: '初期', requiredQi: 30500, totalAccumulatedQi: 79700),
  RealmStage(name: '金丹中期', phase: '金丹期', subStage: '中期', requiredQi: 49350, totalAccumulatedQi: 129050),
  RealmStage(name: '金丹后期', phase: '金丹期', subStage: '后期', requiredQi: 79850, totalAccumulatedQi: 208900),

  RealmStage(name: '元婴初期', phase: '元婴期', subStage: '初期', requiredQi: 129200, totalAccumulatedQi: 338100),
  RealmStage(name: '元婴中期', phase: '元婴期', subStage: '中期', requiredQi: 209050, totalAccumulatedQi: 547150),
  RealmStage(name: '元婴后期', phase: '元婴期', subStage: '后期', requiredQi: 338250, totalAccumulatedQi: 885400),

  RealmStage(name: '化神初期', phase: '化神期', subStage: '初期', requiredQi: 547300, totalAccumulatedQi: 1432700),
  RealmStage(name: '化神中期', phase: '化神期', subStage: '中期', requiredQi: 885550, totalAccumulatedQi: 2318250),
  RealmStage(name: '化神后期', phase: '化神期', subStage: '后期', requiredQi: 1432850, totalAccumulatedQi: 3751100),

  RealmStage(name: '炼虚初期', phase: '炼虚期', subStage: '初期', requiredQi: 2318400, totalAccumulatedQi: 6069500),
  RealmStage(name: '炼虚中期', phase: '炼虚期', subStage: '中期', requiredQi: 3751250, totalAccumulatedQi: 9820750),
  RealmStage(name: '炼虚后期', phase: '炼虚期', subStage: '后期', requiredQi: 6069650, totalAccumulatedQi: 15890400),

  RealmStage(name: '合体初期', phase: '合体期', subStage: '初期', requiredQi: 9820900, totalAccumulatedQi: 25711300),
  RealmStage(name: '合体中期', phase: '合体期', subStage: '中期', requiredQi: 15890550, totalAccumulatedQi: 41601850),
  RealmStage(name: '合体后期', phase: '合体期', subStage: '后期', requiredQi: 25711450, totalAccumulatedQi: 67313300),

  RealmStage(name: '大乘初期', phase: '大乘期', subStage: '初期', requiredQi: 41602000, totalAccumulatedQi: 108915300),
  RealmStage(name: '大乘中期', phase: '大乘期', subStage: '中期', requiredQi: 67313450, totalAccumulatedQi: 176228750),
  RealmStage(name: '大乘后期', phase: '大乘期', subStage: '后期', requiredQi: 108915450, totalAccumulatedQi: 285144200),

  // 渡劫九重
  RealmStage(name: '渡劫一重', phase: '渡劫期', subStage: '一劫', requiredQi: 170000000, totalAccumulatedQi: 455144200),
  RealmStage(name: '渡劫二重', phase: '渡劫期', subStage: '二劫', requiredQi: 180000000, totalAccumulatedQi: 635144200),
  RealmStage(name: '渡劫三重', phase: '渡劫期', subStage: '三劫', requiredQi: 190000000, totalAccumulatedQi: 825144200),
  RealmStage(name: '渡劫四重', phase: '渡劫期', subStage: '四劫', requiredQi: 200000000, totalAccumulatedQi: 1025144200),
  RealmStage(name: '渡劫五重', phase: '渡劫期', subStage: '五劫', requiredQi: 210000000, totalAccumulatedQi: 1235144200),
  RealmStage(name: '渡劫六重', phase: '渡劫期', subStage: '六劫', requiredQi: 220000000, totalAccumulatedQi: 1455144200),
  RealmStage(name: '渡劫七重', phase: '渡劫期', subStage: '七劫', requiredQi: 230000000, totalAccumulatedQi: 1685144200),
  RealmStage(name: '渡劫八重', phase: '渡劫期', subStage: '八劫', requiredQi: 240000000, totalAccumulatedQi: 1925144200),
  RealmStage(name: '渡劫九重', phase: '渡劫期', subStage: '九劫', requiredQi: 250000000, totalAccumulatedQi: 2175144200),

  // 补上仙界完整十二境，每境三段
  RealmStage(name: '地仙初期', phase: '地仙', subStage: '初期', requiredQi: 260000000, totalAccumulatedQi: 2435144200),
  RealmStage(name: '地仙中期', phase: '地仙', subStage: '中期', requiredQi: 270000000, totalAccumulatedQi: 2705144200),
  RealmStage(name: '地仙后期', phase: '地仙', subStage: '后期', requiredQi: 280000000, totalAccumulatedQi: 2985144200),

  RealmStage(name: '天仙初期', phase: '天仙', subStage: '初期', requiredQi: 290000000, totalAccumulatedQi: 3275144200),
  RealmStage(name: '天仙中期', phase: '天仙', subStage: '中期', requiredQi: 300000000, totalAccumulatedQi: 3575144200),
  RealmStage(name: '天仙后期', phase: '天仙', subStage: '后期', requiredQi: 310000000, totalAccumulatedQi: 3885144200),

  RealmStage(name: '真仙初期', phase: '真仙', subStage: '初期', requiredQi: 320000000, totalAccumulatedQi: 4205144200),
  RealmStage(name: '真仙中期', phase: '真仙', subStage: '中期', requiredQi: 330000000, totalAccumulatedQi: 4535144200),
  RealmStage(name: '真仙后期', phase: '真仙', subStage: '后期', requiredQi: 340000000, totalAccumulatedQi: 4875144200),

  RealmStage(name: '玄仙初期', phase: '玄仙', subStage: '初期', requiredQi: 350000000, totalAccumulatedQi: 5225144200),
  RealmStage(name: '玄仙中期', phase: '玄仙', subStage: '中期', requiredQi: 360000000, totalAccumulatedQi: 5585144200),
  RealmStage(name: '玄仙后期', phase: '玄仙', subStage: '后期', requiredQi: 370000000, totalAccumulatedQi: 5955144200),

  RealmStage(name: '灵仙初期', phase: '灵仙', subStage: '初期', requiredQi: 380000000, totalAccumulatedQi: 6335144200),
  RealmStage(name: '灵仙中期', phase: '灵仙', subStage: '中期', requiredQi: 390000000, totalAccumulatedQi: 6725144200),
  RealmStage(name: '灵仙后期', phase: '灵仙', subStage: '后期', requiredQi: 400000000, totalAccumulatedQi: 7125144200),

  RealmStage(name: '虚仙初期', phase: '虚仙', subStage: '初期', requiredQi: 410000000, totalAccumulatedQi: 7535144200),
  RealmStage(name: '虚仙中期', phase: '虚仙', subStage: '中期', requiredQi: 420000000, totalAccumulatedQi: 7955144200),
  RealmStage(name: '虚仙后期', phase: '虚仙', subStage: '后期', requiredQi: 430000000, totalAccumulatedQi: 8385144200),

  RealmStage(name: '圣仙初期', phase: '圣仙', subStage: '初期', requiredQi: 440000000, totalAccumulatedQi: 8825144200),
  RealmStage(name: '圣仙中期', phase: '圣仙', subStage: '中期', requiredQi: 450000000, totalAccumulatedQi: 9275144200),
  RealmStage(name: '圣仙后期', phase: '圣仙', subStage: '后期', requiredQi: 460000000, totalAccumulatedQi: 9735144200),

  RealmStage(name: '混元仙初期', phase: '混元仙', subStage: '初期', requiredQi: 470000000, totalAccumulatedQi: 10285144200),
  RealmStage(name: '混元仙中期', phase: '混元仙', subStage: '中期', requiredQi: 480000000, totalAccumulatedQi: 10765144200),
  RealmStage(name: '混元仙后期', phase: '混元仙', subStage: '后期', requiredQi: 490000000, totalAccumulatedQi: 11255144200),

  RealmStage(name: '太乙仙初期', phase: '太乙仙', subStage: '初期', requiredQi: 500000000, totalAccumulatedQi: 11755144200),
  RealmStage(name: '太乙仙中期', phase: '太乙仙', subStage: '中期', requiredQi: 510000000, totalAccumulatedQi: 12265144200),
  RealmStage(name: '太乙仙后期', phase: '太乙仙', subStage: '后期', requiredQi: 520000000, totalAccumulatedQi: 12785144200),

  RealmStage(name: '太清仙初期', phase: '太清仙', subStage: '初期', requiredQi: 530000000, totalAccumulatedQi: 13315144200),
  RealmStage(name: '太清仙中期', phase: '太清仙', subStage: '中期', requiredQi: 540000000, totalAccumulatedQi: 13855144200),
  RealmStage(name: '太清仙后期', phase: '太清仙', subStage: '后期', requiredQi: 550000000, totalAccumulatedQi: 14405144200),

  RealmStage(name: '至尊仙帝初期', phase: '至尊仙帝', subStage: '初期', requiredQi: 560000000, totalAccumulatedQi: 14965144200),
  RealmStage(name: '至尊仙帝中期', phase: '至尊仙帝', subStage: '中期', requiredQi: 570000000, totalAccumulatedQi: 15535144200),
  RealmStage(name: '至尊仙帝后期', phase: '至尊仙帝', subStage: '后期', requiredQi: 580000000, totalAccumulatedQi: 16115144200),
  RealmStage(name: '至尊仙帝大圆满', phase: '至尊仙帝', subStage: '大圆满', requiredQi: 600000000, totalAccumulatedQi: 16715144200),

  RealmStage(name: '退休仙帝', phase: '退休', subStage: '无', requiredQi: 0, totalAccumulatedQi: 16715144200),
];
