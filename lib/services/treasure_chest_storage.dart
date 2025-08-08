import 'package:hive/hive.dart';

class TreasureChestStorage {
  static const _boxName = 'opened_chests';

  /// ✅ 标记宝箱为已开启
  static Future<void> markAsOpenedTile(String tileKey) async {
    final box = await Hive.openBox(_boxName); // 每次 open，自动复用
    await box.put(tileKey, true);
  }

  /// ✅ 判断宝箱是否已开启（同步版建议不要，改异步更靠谱）
  static Future<bool> isOpenedTile(String tileKey) async {
    final box = await Hive.openBox(_boxName); // 不用 preload，不用缓存
    return box.get(tileKey, defaultValue: false) ?? false;
  }

  /// ✅ 清空全部宝箱记录（调试用）
  static Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  /// ✅ 获取所有已开启的 tileKey（调试用）
  static Future<List<String>> getAllOpenedKeys() async {
    final box = await Hive.openBox(_boxName);
    return box.keys.cast<String>().toList();
  }
}
