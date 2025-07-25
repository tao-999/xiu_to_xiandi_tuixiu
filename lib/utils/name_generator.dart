import 'dart:math';

enum NameComponentType { male, female, neutral }

class Surnames {
  static const List<String> all = [
    "赵", "钱", "孙", "李", "周", "吴", "郑", "王", "冯", "陈", "褚", "卫", "蒋", "沈", "韩", "杨",
    "朱", "秦", "尤", "许", "何", "吕", "施", "张", "孔", "曹", "严", "华", "金", "魏", "陶", "姜", "谢", "邹",
    "喻", "柏", "水", "窦", "章", "云", "苏", "潘", "葛", "范", "彭", "郎", "鲁", "韦", "马", "苗", "凤", "花",
    "方", "俞", "任", "袁", "柳", "史", "唐", "费", "廉", "薛", "雷", "贺", "倪", "汤", "滕", "殷", "罗", "毕",
    "郝", "邬", "安", "常", "乐", "于", "时", "傅", "皮", "卞", "齐", "康", "伍", "余", "元", "卜", "顾", "孟",
    "黄", "和", "穆", "萧", "尹", "姚", "邵", "湛", "汪", "祁", "毛", "禹", "狄", "米", "贝", "明", "臧", "计",
    "伏", "成", "戴", "谈", "宋", "茅", "庞", "熊", "纪", "舒", "屈", "项", "祝", "董", "梁", "杜", "阮", "蓝",
    "欧阳", "司马", "上官", "夏侯", "诸葛", "东方", "皇甫", "尉迟", "公孙", "令狐",
    "长孙", "慕容", "宇文", "司徒", "轩辕", "司空", "呼延", "端木", "赫连", "拓跋",
    "百里", "东郭", "南宫", "西门", "独孤", "南荣", "北堂", "澹台", "公冶", "宗政",
    "濮阳", "太史", "仲孙", "钟离", "宰父", "谷梁", "晋楚", "闾丘", "子车", "亓官",
    "羊舌", "微生", "梁丘", "公良", "乐正", "漆雕", "壤驷", "公西", "申屠", "公羊",
    "公户", "公玉", "公仪", "梁馀", "公仲", "公上", "公门", "公乘", "太叔", "申叔"
  ];

  static String random() => all[Random().nextInt(all.length)];
}

class NameCharacters {
  static const List<String> female = [
    "云", "风", "羽", "灵", "月", "星", "雪", "晨", "曦", "潇", "夜", "秋", "瑶", "璃", "若", "竹",
    "冰", "蓝", "晴", "梦", "思", "悠", "璇", "岚", "烨", "宸", "萱", "紫", "嫣", "绫", "舞", "珞",
    "琪", "钰", "霓", "珺", "珂", "妍", "婉", "柔", "语", "清", "凝", "雅", "菲", "惜", "绮", "悦",
    "香", "芝", "芷", "恬", "寒", "曼", "琳", "瑾", "环", "蕊", "芮", "绣", "微", "昕", "滢", "沫",
    "茗", "杳", "栀", "箐", "栖", "葶", "葭"
  ];

  static const List<String> male = [
    "血", "魔", "煞", "鬼", "影", "邪", "幽", "魂", "灭", "噬", "焱", "葬", "狱", "殇", "绝", "裂",
    "魇", "戮", "刹", "冥", "戈", "狂", "战", "雷", "烈", "修", "弑", "踏", "狞", "霸", "斩", "杀",
    "怒", "锋", "凛", "凨", "晦", "疾", "罡", "刑", "震", "狰", "啸", "祸", "骁", "枫", "炎", "凌",
    "烬", "焚", "寒", "玄", "苍", "轩", "岳"
  ];

  static const List<String> neutral = [
    "玄", "尘", "墨", "岱", "渊", "临", "弈", "泽", "聆", "渺", "溟", "空", "界", "行", "陌", "归",
    "鸿", "望", "衡", "承", "镜", "辰", "巫", "逍", "遥", "槐", "岩", "珩", "言", "识", "策", "悟",
    "迹", "溯", "葵", "符", "卜", "卦", "术", "阵", "丹", "器", "宝", "魄", "体", "气", "意", "念",
    "魂", "咒", "禅", "妙", "极", "元", "始", "终", "真", "寂", "轮", "神", "劫", "命", "运", "道",
    "缘", "因", "果", "梦", "戒", "锁", "印", "兆", "祭", "赫", "嵇", "逄", "阙", "雍", "褚", "闾",
    "郗", "隗", "无", "觉", "虚", "照", "慈", "悲", "慧", "湛", "止", "静", "恒", "明", "梵", "镜",
    "魉", "魍", "尸", "蛊", "诡", "缚", "咎", "蚀", "渎", "炼", "觞", "瘴", "疫", "怨", "昼", "晷",
    "晖", "星", "朔", "昙", "宙", "陨", "逝", "曜", "寰", "暝"
  ];

  static List<String> getPool(NameComponentType type) {
    switch (type) {
      case NameComponentType.female:
        return female;
      case NameComponentType.male:
        return male;
      case NameComponentType.neutral:
        return neutral;
    }
  }

  static String pick(NameComponentType type) {
    final pool = getPool(type);
    return pool[Random().nextInt(pool.length)];
  }

  static String pickForSingleName(bool isMale) {
    final pool = isMale ? [...male, ...neutral] : [...female, ...neutral];
    return pool[Random().nextInt(pool.length)];
  }
}

class NameGenerator {
  static final _rand = Random();

  static String generate({
    required bool isMale,
    Random? rand,
  }) {
    final r = rand ?? _rand;

    final surname = Surnames.all[r.nextInt(Surnames.all.length)];

    // 🔄 25% 概率生成单字名
    final isTwoChar = r.nextDouble() > 0.25;

    if (!isTwoChar) {
      final pool = isMale
          ? [...NameCharacters.male, ...NameCharacters.neutral]
          : [...NameCharacters.female, ...NameCharacters.neutral];
      final char = pool[r.nextInt(pool.length)];
      return surname + char;
    }

    // 双字名结构
    List<NameComponentType> components;
    final coin = r.nextDouble();
    if (isMale) {
      components = coin < 0.5
          ? [NameComponentType.male, NameComponentType.neutral]
          : (r.nextBool()
          ? [NameComponentType.neutral, NameComponentType.male]
          : [NameComponentType.male, NameComponentType.male]);
    } else {
      components = coin < 0.5
          ? [NameComponentType.female, NameComponentType.neutral]
          : (r.nextBool()
          ? [NameComponentType.neutral, NameComponentType.female]
          : [NameComponentType.female, NameComponentType.female]);
    }

    final first = NameCharacters.getPool(components[0])[r.nextInt(NameCharacters.getPool(components[0]).length)];
    String second;
    do {
      second = NameCharacters.getPool(components[1])[r.nextInt(NameCharacters.getPool(components[1]).length)];
    } while (second == first);

    return surname + first + second;
  }

  // ✅ 兼容旧调用方式
  static String generateWithSeed(Random rand, {bool isMale = true}) {
    return generate(isMale: isMale, rand: rand);
  }
}

