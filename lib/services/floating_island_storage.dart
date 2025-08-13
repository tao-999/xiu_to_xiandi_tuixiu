// 📄 lib/services/floating_island_storage.dart
import 'package:hive/hive.dart';

class FloatingIslandStorage {
  static Box? _box;

  static Future<void> _ensureBox() async {
    _box = await Hive.openBox('floating_island');
  }

  static Future<Box> ensureBoxAndGet() async {
    if (_box == null) {
      _box = await Hive.openBox('floating_island');
    }
    return _box!;
  }

  // ========== 小工具：消毒（防止 NaN/Infinity 写入） ==========
  static double _sanitizeDouble(num v, {double cap = 1e30}) {
    final d = v.toDouble();
    if (!d.isFinite) return 0.0;
    if (d >  cap) return  cap;
    if (d < -cap) return -cap;
    return d;
  }

  /// 保存角色位置（局部）
  static Future<void> savePlayerPosition(double x, double y) async {
    await _ensureBox();
    final sx = _sanitizeDouble(x);
    final sy = _sanitizeDouble(y);
    await _box!.put('player_x', sx);
    await _box!.put('player_y', sy);
    print('[FloatingIslandStorage] Saved player position(local): x=$sx, y=$sy');
  }

  /// 获取角色位置（局部）
  static Future<Map<String, double>?> getPlayerPosition() async {
    await _ensureBox();
    final x = _box!.get('player_x') as double?;
    final y = _box!.get('player_y') as double?;
    if (x != null && y != null) {
      final sx = _sanitizeDouble(x);
      final sy = _sanitizeDouble(y);
      print('[FloatingIslandStorage] Loaded player position(local): x=$sx, y=$sy');
      return {'x': sx, 'y': sy};
    }
    print('[FloatingIslandStorage] No player position found.');
    return null;
  }

  /// 保存地图窗口位置（局部相机中心）
  static Future<void> saveCameraOffset(double offsetX, double offsetY) async {
    await _ensureBox();
    final sx = _sanitizeDouble(offsetX);
    final sy = _sanitizeDouble(offsetY);
    await _box!.put('camera_x', sx);
    await _box!.put('camera_y', sy);
    print('[FloatingIslandStorage] Saved camera offset(local): x=$sx, y=$sy');
  }

  /// 获取地图窗口位置（局部相机中心）
  static Future<Map<String, double>?> getCameraOffset() async {
    await _ensureBox();
    final x = _box!.get('camera_x') as double?;
    final y = _box!.get('camera_y') as double?;
    if (x != null && y != null) {
      final sx = _sanitizeDouble(x);
      final sy = _sanitizeDouble(y);
      print('[FloatingIslandStorage] Loaded camera offset(local): x=$sx, y=$sy');
      return {'x': sx, 'y': sy};
    }
    print('[FloatingIslandStorage] No camera offset found.');
    return null;
  }

  /// 清空所有存储
  static Future<void> clear() async {
    await _ensureBox();
    await _box!.clear();
    print('[FloatingIslandStorage] Storage cleared.');
  }

  /// 保存seed
  static Future<void> saveSeed(int seed) async {
    await _ensureBox();
    await _box!.put('seed', seed);
    print('[FloatingIslandStorage] Saved seed: $seed');
  }

  /// 获取seed
  static Future<int?> getSeed() async {
    await _ensureBox();
    final seed = _box!.get('seed') as int?;
    if (seed != null) {
      print('[FloatingIslandStorage] Loaded seed: $seed');
    } else {
      print('[FloatingIslandStorage] No seed found.');
    }
    return seed;
  }

  /// 保存某个tile的动态对象列表
  static Future<void> saveDynamicObjectsForTile(
      String tileKey,
      List<Map<String, dynamic>> objects,
      ) async {
    await _ensureBox();
    await _box!.put('dynamic_$tileKey', objects);
  }

  /// 加载某个tile的动态对象列表
  static Future<List<Map<String, dynamic>>?> getDynamicObjectsForTile(String tileKey) async {
    await _ensureBox();
    final result = _box!.get('dynamic_$tileKey');
    if (result is List) {
      print('[FloatingIslandStorage] Loaded dynamic objects for $tileKey: ${result.length} objects.');
      return List<Map<String, dynamic>>.from(result);
    }
    return null;
  }

  /// 删除某个tile的动态对象
  static Future<void> removeDynamicObjectsForTile(String tileKey) async {
    await _ensureBox();
    await _box!.delete('dynamic_$tileKey');
  }

  /// 保存某个tile的静态对象列表
  static Future<void> saveStaticObjectsForTile(
      String tileKey,
      List<Map<String, dynamic>> objects,
      ) async {
    await _ensureBox();
    await _box!.put('static_$tileKey', objects);
    print('[FloatingIslandStorage] Saved static objects for $tileKey (${objects.length} items)');
  }

  /// 加载某个tile的静态对象列表
  static Future<List<Map<String, dynamic>>?> getStaticObjectsForTile(String tileKey) async {
    await _ensureBox();
    final result = _box!.get('static_$tileKey');
    if (result is List) {
      print('[FloatingIslandStorage] Loaded static objects for $tileKey (${result.length} items)');
      return List<Map<String, dynamic>>.from(result);
    }
    return null;
  }

  /// 删除某个tile的静态对象
  static Future<void> removeStaticObjectsForTile(String tileKey) async {
    await _ensureBox();
    await _box!.delete('static_$tileKey');
    print('[FloatingIslandStorage] Removed static objects for $tileKey');
  }

  static Future<bool> staticTileExists(String tileKey) async {
    await _ensureBox();
    return _box!.containsKey('static_$tileKey');
  }

  // ========== 新增：保存 / 读取 世界基准（浮动原点累计） ==========
  static Future<void> saveWorldBase(double x, double y) async {
    await _ensureBox();
    final sx = _sanitizeDouble(x);
    final sy = _sanitizeDouble(y);
    await _box!.put('world_base_x', sx);
    await _box!.put('world_base_y', sy);
    print('[FloatingIslandStorage] Saved worldBase: x=$sx, y=$sy');
  }

  static Future<Map<String, double>?> getWorldBase() async {
    await _ensureBox();
    final x = _box!.get('world_base_x') as double?;
    final y = _box!.get('world_base_y') as double?;
    if (x != null && y != null) {
      final sx = _sanitizeDouble(x);
      final sy = _sanitizeDouble(y);
      print('[FloatingIslandStorage] Loaded worldBase: x=$sx, y=$sy');
      return {'x': sx, 'y': sy};
    }
    print('[FloatingIslandStorage] No worldBase found.');
    return null;
  }
}
