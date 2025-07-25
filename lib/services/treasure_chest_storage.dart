import 'package:hive/hive.dart';
import 'package:flame/components.dart';

class TreasureChestStorage {
  static const _boxName = 'opened_chests';

  static final Map<String, bool> _cachedStates = {};

  /// ✅ 内部统一 key 生成
  static String _keyFor(Vector2 pos) => '${pos.x.toInt()},${pos.y.toInt()}';

  /// ✅ 标记某个宝箱为已开启（写入 Hive + 缓存）
  static Future<void> markAsOpened(Vector2 pos) async {
    final box = await Hive.openBox(_boxName);
    final key = _keyFor(pos);
    await box.put(key, true);
    _cachedStates[key] = true;
  }

  /// ✅ 同步判断是否开启（从缓存中查）
  static bool isOpenedSync(Vector2 pos) {
    final key = _keyFor(pos);
    return _cachedStates[key] ?? false;
  }

  /// ✅ 加载所有已开启宝箱（初始化时调用）
  static Future<void> preloadAllOpenedStates() async {
    final box = await Hive.openBox(_boxName);
    _cachedStates
      ..clear()
      ..addAll(Map<String, bool>.fromEntries(
        box.keys.map((k) => MapEntry(k.toString(), true)),
      ));
  }

  /// 🧪 调试用：清空所有记录（Hive + 缓存）
  static Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    _cachedStates.clear();
  }

  /// ✅ 获取所有已打开坐标（调试用）
  static Future<List<String>> getAllOpenedKeys() async {
    final box = await Hive.openBox(_boxName);
    return box.keys.cast<String>().toList();
  }
}
