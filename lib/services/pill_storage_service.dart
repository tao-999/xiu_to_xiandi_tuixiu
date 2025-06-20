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
    await box.add(pill);
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
}
