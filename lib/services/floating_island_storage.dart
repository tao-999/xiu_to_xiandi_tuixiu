import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class FloatingIslandStorage {
  static Box? _box;

  static Future<void> _ensureBox() async {
    _box = await Hive.openBox('floating_island');
  }

  /// 保存角色位置
  static Future<void> savePlayerPosition(double x, double y) async {
    await _ensureBox();
    await _box!.put('player_x', x);
    await _box!.put('player_y', y);
    print('[FloatingIslandStorage] Saved player position: x=$x, y=$y');
  }

  /// 获取角色位置
  static Future<Map<String, double>?> getPlayerPosition() async {
    await _ensureBox();
    final x = _box!.get('player_x') as double?;
    final y = _box!.get('player_y') as double?;
    if (x != null && y != null) {
      print('[FloatingIslandStorage] Loaded player position: x=$x, y=$y');
      return {'x': x, 'y': y};
    }
    print('[FloatingIslandStorage] No player position found.');
    return null;
  }

  /// 保存地图窗口位置
  static Future<void> saveCameraOffset(double offsetX, double offsetY) async {
    await _ensureBox();
    await _box!.put('camera_x', offsetX);
    await _box!.put('camera_y', offsetY);
    print('[FloatingIslandStorage] Saved camera offset: x=$offsetX, y=$offsetY');
  }

  /// 获取地图窗口位置
  static Future<Map<String, double>?> getCameraOffset() async {
    await _ensureBox();
    final x = _box!.get('camera_x') as double?;
    final y = _box!.get('camera_y') as double?;
    if (x != null && y != null) {
      print('[FloatingIslandStorage] Loaded camera offset: x=$x, y=$y');
      return {'x': x, 'y': y};
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

}
