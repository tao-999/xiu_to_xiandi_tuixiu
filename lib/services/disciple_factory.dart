import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/name_generator.dart';

import '../data/initial_disciple_pool.dart';

final _rng = Random();

const String _drawsKey = 'draws_since_beauty_card';
const String _currentRangeKey = 'current_card_range';
const String _usedUniqueAptitudesKey = 'used_unique_aptitudes';

/// 🎲 主抽卡逻辑（支持卡池解锁 + 保底）
Future<int> generateHumanAptitude() async {
  final prefs = await SharedPreferences.getInstance();
  int count = prefs.getInt(_drawsKey) ?? 0;
  int maxRange = prefs.getInt(_currentRangeKey) ?? 40;
  final used = prefs.getStringList(_usedUniqueAptitudesKey)?.map(int.parse).toSet() ?? {};

  // ✅ 当前池中最大资质（如100）
  final maxAvailableAptitude = initialDiscipleRawPool
      .map((e) => e['aptitude'] as int)
      .reduce(max);

  // ✅ 当前区间是否抽完，如果是，往上扩展
  final remaining = initialDiscipleRawPool
      .where((d) => !used.contains(d['aptitude']) && d['aptitude'] <= maxRange)
      .toList();

  if (remaining.isEmpty && maxRange < maxAvailableAptitude) {
    maxRange += 10;
    count = 0;
    await prefs.setInt(_currentRangeKey, maxRange);
    await prefs.setInt(_drawsKey, 0);
  }

  // ✅ 重新获取卡池（含扩展后）
  final currentPool = initialDiscipleRawPool
      .where((d) => !used.contains(d['aptitude']) && d['aptitude'] <= maxRange)
      .toList();

  final isPoolEmpty = currentPool.isEmpty;

  if (!isPoolEmpty) {
    count++;
    final roll = _rng.nextInt(80);

    if (count >= 80 || roll == 0) {
      await prefs.setInt(_drawsKey, 0);
      final chosen = currentPool[_rng.nextInt(currentPool.length)];
      return chosen['aptitude'];
    } else {
      await prefs.setInt(_drawsKey, count);
    }
  }

  // 🧟 SSR 全部抽光 or 没抽中 → 进入炮灰池
  return 1 + _rng.nextInt(30);
}

/// 🖼️ 炮灰通用贴图
String getImageForAptitude(int apt) {
  if (apt <= 4) return 'assets/images/lianqi.png';
  if (apt <= 8) return 'assets/images/zhuji.png';
  if (apt <= 12) return 'assets/images/jindan.png';
  if (apt <= 16) return 'assets/images/yuanying.png';
  if (apt <= 20) return 'assets/images/huashen.png';
  if (apt <= 24) return 'assets/images/lianxu.png';
  if (apt <= 27) return 'assets/images/heti.png';
  return 'assets/images/dacheng.png'; // 28~30 默认封顶贴图
}

/// 🧙‍♀️ 弟子工厂（整合所有招募逻辑）
class DiscipleFactory {
  static Future<Disciple> generateRandom() async {
    final uuid = const Uuid();
    final aptitude = await generateHumanAptitude();
    final isFemale = _rng.nextBool();
    final gender = isFemale ? 'female' : 'male';
    final name = NameGenerator.generate(isMale: !isFemale);
    final age = 0;

    if (aptitude >= 31) {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getStringList(_usedUniqueAptitudesKey)?.map(int.parse).toSet() ?? {};

      final available = initialDiscipleRawPool
          .where((d) => !used.contains(d['aptitude']) && d['aptitude'] == aptitude)
          .toList();

      if (available.isNotEmpty) {
        final selected = available[_rng.nextInt(available.length)];
        final selectedApt = selected['aptitude'] as int;

        used.add(selectedApt);
        await prefs.setStringList(
            _usedUniqueAptitudesKey, used.map((e) => e.toString()).toList());

        return Disciple(
          id: uuid.v4(),
          name: selected['name'],
          gender: selected['gender'],
          age: age,
          aptitude: selectedApt,
          hp: selected['hp'],
          atk: selected['atk'],
          def: selected['def'],
          realm: '凡人',
          imagePath: selected['imagePath'],
        );
      }
    }

    // 🧟 没抽到专属卡，生成随机炮灰
    return Disciple(
      id: uuid.v4(),
      name: name,
      gender: aptitude < 31 ? 'male' : gender,
      age: age,
      aptitude: aptitude,
      hp: 10,
      atk: 2,
      def: 1,
      realm: '凡人',
      imagePath: getImageForAptitude(aptitude),
    );
  }
}

/// 🔄 重置抽卡记录（调试用）
Future<void> resetInitialDiscipleDraws() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_drawsKey);
  await prefs.remove(_currentRangeKey);
  await prefs.remove(_usedUniqueAptitudesKey);
}

/// 🔍 判断 SSR 是否已全部抽完（可用于隐藏保底提示）
Future<bool> isSsrPoolEmpty() async {
  final prefs = await SharedPreferences.getInstance();
  final used = prefs.getStringList(_usedUniqueAptitudesKey)?.map(int.parse).toSet() ?? {};
  final all = initialDiscipleRawPool.map((e) => e['aptitude'] as int).toSet();

  return used.containsAll(all);
}
