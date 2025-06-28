import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class FloatingIslandStorage {
  static Box? _box;

  static Future<void> _ensureBox() async {
    if (_box != null) return;
    // 删掉这行！Hive.init(dir.path);
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
}
