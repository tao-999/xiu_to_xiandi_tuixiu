import 'dart:math';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class NoiseCacheService {
  static Box<double>? _box;

  // 懒加载
  static Future<void> _ensureBox() async {
    if (_box != null) return;
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _box = await Hive.openBox<double>('noise_cache');
  }

  static String _key(int x, int y) => '${x}_$y';

  /// 获取缓存（如果没有就返回null）
  static Future<double?> get(int x, int y) async {
    await _ensureBox();
    return _box!.get(_key(x, y));
  }

  /// 写入缓存（异步）
  static Future<void> put(int x, int y, double value) async {
    await _ensureBox();
    await _box!.put(_key(x, y), value);
  }

  /// 清空缓存
  static Future<void> clear() async {
    await _ensureBox();
    await _box!.clear();
  }
}
