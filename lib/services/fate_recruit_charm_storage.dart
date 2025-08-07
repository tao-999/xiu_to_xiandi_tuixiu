import 'package:hive/hive.dart';

class FateRecruitCharmStorage {
  static const _boxName = 'collected_fate_recruit_charm_box';
  static Box<bool>? _box;

  /// 📦 获取 Hive Box
  static Future<Box<bool>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<bool>(_boxName);
    return _box!;
  }

  /// ✅ 标记为已拾取（通过 tileKey）
  static Future<void> markCollected(String tileKey) async {
    final box = await _getBox();
    await box.put(tileKey, true);
  }

  /// ❓ 是否已拾取（通过 tileKey）
  static Future<bool> isCollected(String tileKey) async {
    final box = await _getBox();
    return box.get(tileKey, defaultValue: false) ?? false;
  }

  /// 📃 获取所有已拾取的 tileKey
  static Future<List<String>> getAllCollectedKeys() async {
    final box = await _getBox();
    return box.keys.cast<String>().toList();
  }

  /// 🧹 清空所有记录
  static Future<void> clearCollectedKeys() async {
    final box = await _getBox();
    await box.clear();
  }
}
