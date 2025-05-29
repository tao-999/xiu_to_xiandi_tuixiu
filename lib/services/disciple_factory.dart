import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/name_generator.dart';

/// ------------------------------
/// 资质权重结构体
/// ------------------------------
class _AptitudeEntry {
  final int min;
  final int max;
  final int weight;

  const _AptitudeEntry(this.min, this.max, this.weight);
}

/// ------------------------------
/// 人界资质权重（总和 1000）
/// ------------------------------
const List<_AptitudeEntry> _humanAptitudeTable = [
  _AptitudeEntry(81, 90, 1),    // 渡劫期 - 0.1%
  _AptitudeEntry(71, 80, 10),   // 大乘期 - 1%
  _AptitudeEntry(61, 70, 30),   // 合体期 - 3%
  _AptitudeEntry(51, 60, 60),   // 炼虚期 - 6%
  _AptitudeEntry(41, 50, 100),  // 化神期 - 10%
  _AptitudeEntry(31, 40, 200),  // 元婴期 - 20%
  _AptitudeEntry(21, 30, 250),  // 金丹期 - 25%
  _AptitudeEntry(11, 20, 200),  // 筑基期 - 20%
  _AptitudeEntry(1, 10, 149),   // 练气期 - 14.9%
];

/// ------------------------------
/// 仙界资质权重（总和约 1994）
/// ------------------------------
const List<_AptitudeEntry> _immortalAptitudeTable = [
  _AptitudeEntry(101, 110, 700),  // 地仙
  _AptitudeEntry(111, 120, 600),  // 天仙
  _AptitudeEntry(121, 130, 500),  // 真仙
  _AptitudeEntry(131, 140, 330),  // 玄仙
  _AptitudeEntry(141, 150, 300),  // 灵仙
  _AptitudeEntry(151, 160, 200),  // 虚仙
  _AptitudeEntry(161, 170, 100),  // 圣仙
  _AptitudeEntry(171, 180, 50),   // 混元仙
  _AptitudeEntry(181, 190, 10),   // 太乙仙
  _AptitudeEntry(191, 200, 2),    // 太清仙
  _AptitudeEntry(201, 210, 2),    // 至尊仙帝（可调整权重）
];

final _rng = Random();
int _drawsSinceLastDuJie = 0; // 渡劫保底计数器

/// ------------------------------
/// 根据权重表随机生成资质
/// ------------------------------
int _generateAptitude(List<_AptitudeEntry> table) {
  int totalWeight = 0;
  for (var e in table) {
    totalWeight += e.weight;
  }
  int roll = _rng.nextInt(totalWeight);

  for (final entry in table) {
    if (roll < entry.weight) {
      return entry.min + _rng.nextInt(entry.max - entry.min + 1);
    }
    roll -= entry.weight;
  }
  // 万一没匹配到，默认最低
  final last = table.last;
  return last.min + _rng.nextInt(last.max - last.min + 1);
}

/// ------------------------------
/// 生成人界资质，带渡劫保底机制
/// ------------------------------
int generateHumanAptitude() {
  _drawsSinceLastDuJie++;

  if (_drawsSinceLastDuJie >= 100) {
    _drawsSinceLastDuJie = 0;
    return _rng.nextInt(10) + 81; // 81-90渡劫期强制爆
  }

  int aptitude = _generateAptitude(_humanAptitudeTable);
  if (aptitude >= 81) {
    _drawsSinceLastDuJie = 0; // 出渡劫重置保底计数
  }
  return aptitude;
}

/// ------------------------------
/// 资质到境界映射（人界）
/// ------------------------------
String _mapHumanAptitudeToRealm(int aptitude) {
  if (aptitude >= 81) return "渡劫期";
  if (aptitude >= 71) return "大乘期";
  if (aptitude >= 61) return "合体期";
  if (aptitude >= 51) return "炼虚期";
  if (aptitude >= 41) return "化神期";
  if (aptitude >= 31) return "元婴期";
  if (aptitude >= 21) return "金丹期";
  if (aptitude >= 11) return "筑基期";
  return "练气期";
}

/// ------------------------------
/// 资质到境界映射（仙界）
/// ------------------------------
String _mapImmortalAptitudeToRealm(int aptitude) {
  if (aptitude >= 201) return "至尊仙帝";
  if (aptitude >= 191) return "太清仙";
  if (aptitude >= 181) return "太乙仙";
  if (aptitude >= 171) return "混元仙";
  if (aptitude >= 161) return "圣仙";
  if (aptitude >= 151) return "虚仙";
  if (aptitude >= 141) return "灵仙";
  if (aptitude >= 131) return "玄仙";
  if (aptitude >= 121) return "真仙";
  if (aptitude >= 111) return "天仙";
  return "地仙";
}

/// ------------------------------
/// 内嵌特长生成器
/// ------------------------------
class SpecialtyGenerator {
  static const List<String> _options = [
    "剑术", "符箓", "炼丹", "炼器", "御兽", "驭雷",
    "毒术", "阵法", "控火", "驭水", "冰封", "遁术"
  ];

  static String pick() {
    final list = List<String>.from(_options);
    list.shuffle();
    return list.first;
  }
}

/// ------------------------------
/// 内嵌天赋生成器
/// ------------------------------
class TalentGenerator {
  static const List<String> _options = [
    "灵根纯粹", "神识强大", "身法如电", "百毒不侵", "火系亲和",
    "冰封万物", "御剑天成", "精神免疫", "炼丹奇才", "战意滔天",
    "隐匿天赋", "灵气吞噬"
  ];

  static List<String> pickMultiple(int count) {
    final list = List<String>.from(_options);
    list.shuffle();
    return list.take(count).toList();
  }
}

/// ------------------------------
/// Disciple 工厂方法
/// ------------------------------
class DiscipleFactory {
  static Disciple generateRandom({String pool = 'human'}) {
    final rng = Random();
    final uuid = const Uuid();

    final int aptitude = pool == 'human'
        ? generateHumanAptitude()
        : _generateAptitude(_immortalAptitudeTable);

    final realm = pool == 'human'
        ? _mapHumanAptitudeToRealm(aptitude)
        : _mapImmortalAptitudeToRealm(aptitude);

    final bool isFemale = rng.nextBool();

    return Disciple(
      id: uuid.v4(),
      name: NameGenerator.generate(),
      gender: isFemale ? 'female' : 'male',
      age: 16 + rng.nextInt(40),
      aptitude: aptitude,
      realm: realm,
      loyalty: 30 + rng.nextInt(41),
      specialty: SpecialtyGenerator.pick(),
      talents: TalentGenerator.pickMultiple(2),
      lifespan: 100 + rng.nextInt(200),
      cultivation: 0,
      breakthroughChance: rng.nextInt(15) + 5,
      skills: [],
      fatigue: 0,
      isOnMission: false,
      missionEndTimestamp: null,
    );
  }
}
