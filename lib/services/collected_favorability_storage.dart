// 📂 lib/services/collected_favorability_storage.dart

import 'package:hive/hive.dart';

class CollectedFavorabilityStorage {
  static const _boxName = 'collected_favorability_box';
  static Box<bool>? _box;

  /// 📦 获取 Hive Box
  static Future<Box<bool>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<bool>(_boxName);
    return _box!;
  }

  /// ✅ 标记已采集（通过 tileKey）
  static Future<void> markCollected(String tileKey) async {
    final box = await _getBox();
    await box.put(tileKey, true);
  }

  /// ❓ 是否已采集
  static Future<bool> isCollected(String tileKey) async {
    final box = await _getBox();
    return box.get(tileKey, defaultValue: false) ?? false;
  }

  /// 🧹 清空（开发用）
  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
