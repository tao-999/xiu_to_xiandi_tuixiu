import 'package:hive/hive.dart';
import '../models/pill.dart';

class PillStorageService {
  static const String _boxName = 'pill_box';

  /// 🧪 打开盒子（私有方法）
  static Future<Box<Pill>> _openBox() async {
    return await Hive.openBox<Pill>(_boxName);
  }

  /// ✅ 添加丹药
  static Future<void> addPill(Pill pill) async {
    final box = await _openBox();

    // ✅ 使用 firstOrNull 替代 firstWhere，避免 orElse 报错
    final same = box.values.where((p) =>
    p.name == pill.name &&
        p.level == pill.level &&
        p.type == pill.type &&
        p.bonusAmount == pill.bonusAmount,
    ).cast<Pill>().toList().firstOrNull;

    if (same != null) {
      same.count += pill.count;
      await same.save();
    } else {
      await box.add(pill);
    }
  }

  /// ✅ 删除某个丹药
  static Future<void> deletePillByKey(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  /// ✅ 获取所有丹药
  static Future<List<Pill>> loadAllPills() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// ✅ 获取带 key 的所有丹药
  static Future<Map<dynamic, Pill>> loadPillsWithKeys() async {
    final box = await _openBox();
    return box.toMap();
  }

  /// ✅ 按时间倒序排序
  static Future<List<Pill>> loadSortedByTimeDesc() async {
    final list = await loadAllPills();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// ✅ 清空所有丹药
  static Future<void> clearAllPills() async {
    final box = await _openBox();
    await box.clear();
  }

  /// ✅ 吞服丹药：减少数量，为0时删除
  static Future<void> consumePill(Pill pill, {int count = 1}) async {
    final box = await _openBox();

    final key = pill.key;
    final stored = box.get(key);

    if (stored != null) {
      stored.count -= count;
      if (stored.count <= 0) {
        await stored.delete();
      } else {
        await stored.save();
      }
    }
  }
}
