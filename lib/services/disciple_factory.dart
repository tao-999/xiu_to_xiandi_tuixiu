import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/name_generator.dart';
import 'package:xiu_to_xiandi_tuixiu/services/ssr_disciple_pool.dart';

final _rng = Random();

/// 🎯 保底计数器键名
const String _drawsKey = 'draws_since_ssr';

/// 🧠 获取并更新持久化计数
Future<int> generateHumanAptitude() async {
  final prefs = await SharedPreferences.getInstance();
  int count = prefs.getInt(_drawsKey) ?? 0;
  count++;

  // 🎯 达到保底
  if (count >= 100) {
    await prefs.setInt(_drawsKey, 0);
    return 81 + _rng.nextInt(10); // 强制出 SSR
  }

  int a = _generateAptitude(_humanAptitudeTable);

  if (a >= 81) {
    await prefs.setInt(_drawsKey, 0); // 出 SSR 自动重置
  } else {
    await prefs.setInt(_drawsKey, count); // 更新抽数
  }

  return a;
}

/// 📦 权重结构
class _AptitudeEntry {
  final int min;
  final int max;
  final int weight;
  const _AptitudeEntry(this.min, this.max, this.weight);
}

/// 🎲 人界权重表
const List<_AptitudeEntry> _humanAptitudeTable = [
  _AptitudeEntry(81, 90, 1),
  _AptitudeEntry(71, 80, 10),
  _AptitudeEntry(61, 70, 30),
  _AptitudeEntry(51, 60, 60),
  _AptitudeEntry(41, 50, 100),
  _AptitudeEntry(31, 40, 200),
  _AptitudeEntry(21, 30, 250),
  _AptitudeEntry(11, 20, 200),
  _AptitudeEntry(1, 10, 149),
];

/// 🎲 根据权重随机生成资质
int _generateAptitude(List<_AptitudeEntry> table) {
  int totalWeight = table.fold(0, (sum, e) => sum + e.weight);
  int roll = _rng.nextInt(totalWeight);

  for (final entry in table) {
    if (roll < entry.weight) {
      return entry.min + _rng.nextInt(entry.max - entry.min + 1);
    }
    roll -= entry.weight;
  }
  final last = table.last;
  return last.min + _rng.nextInt(last.max - last.min + 1);
}

/// 🖼️ 资质区间映射通用图片
String getImageForAptitude(int apt) {
  if (apt <= 10) return 'assets/images/lianqi.png';
  if (apt <= 20) return 'assets/images/zhuji.png';
  if (apt <= 30) return 'assets/images/jindan.png';
  if (apt <= 40) return 'assets/images/yuanying.png';
  if (apt <= 50) return 'assets/images/huashen.png';
  if (apt <= 60) return 'assets/images/lianxu.png';
  if (apt <= 70) return 'assets/images/heti.png';
  return 'assets/images/dacheng.png';
}

/// ✅ 主入口：人界招募（支持 SSR Map 池子结构）
class DiscipleFactory {
  static Future<Disciple> generateRandom({String pool = 'human'}) async {
    final uuid = const Uuid();
    final aptitude = await generateHumanAptitude();
    final isFemale = _rng.nextBool();
    final gender = isFemale ? 'female' : 'male';
    final name = NameGenerator.generate(isMale: !isFemale);
    final age = 12 + _rng.nextInt(7); // 12~18岁

    if (aptitude >= 81) {
      // 🎯 SSR 从 raw pool 中找一位
      final matchMap = ssrDiscipleRawPool.firstWhere(
            (d) => d['aptitude'] == aptitude,
        orElse: () => ssrDiscipleRawPool[_rng.nextInt(ssrDiscipleRawPool.length)],
      );

      return Disciple(
        id: uuid.v4(),
        name: matchMap['name'],
        gender: matchMap['gender'],
        age: matchMap['age'],
        aptitude: matchMap['aptitude'],
        hp: matchMap['hp'],
        atk: matchMap['atk'],
        def: matchMap['def'],
        realm: '凡人',
        imagePath: matchMap['imagePath'],
      );
    }

    // 🎲 非 SSR 自由生成
    return Disciple(
      id: uuid.v4(),
      name: name,
      gender: gender,
      age: age,
      aptitude: aptitude,
      hp: 100,
      atk: 20,
      def: 10,
      realm: '凡人',
      imagePath: getImageForAptitude(aptitude),
    );
  }
}
