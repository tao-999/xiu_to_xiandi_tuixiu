// 📂 lib/services/huanyue_storage.dart
import 'dart:convert';

import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HuanyueStorage {
  static const String _killedKey = 'huanyue_killed_enemies';
  static const _playerPosKey = 'huanyue_player_position';
  static const _chestPosKey = 'huanyue_chest_position';
  static const String _floorKey = 'huanyue_floor';

  /// 判断某只怪物是否已被击杀
  static Future<bool> isEnemyKilled(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final killed = prefs.getStringList(_killedKey) ?? [];
    return killed.contains(id);
  }

  /// 标记某只怪物为已击杀
  static Future<void> markEnemyKilled(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final killed = prefs.getStringList(_killedKey) ?? [];
    if (!killed.contains(id)) {
      killed.add(id);
      await prefs.setStringList(_killedKey, killed);
    }
  }

  /// 清空所有击杀记录（调试或重置）
  static Future<void> clearAllKilledEnemies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_killedKey);
  }

  /// 获取所有击杀过的敌人 ID
  static Future<List<String>> getAllKilledEnemies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_killedKey) ?? [];
  }

  /// 保存玩家当前位置
  static Future<void> savePlayerPosition(Vector2 pos) async {
    final prefs = await SharedPreferences.getInstance();
    final value = '${pos.x}_${pos.y}';
    await prefs.setString(_playerPosKey, value);
  }

  /// 读取玩家当前位置
  static Future<Vector2?> getPlayerPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_playerPosKey);
    if (str == null) return null;

    final parts = str.split('_');
    if (parts.length != 2) return null;

    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;

    return Vector2(x, y);
  }

  /// 按楼层保存宝箱位置
  static Future<void> setChestPosition(int floor, Vector2 gridPos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huanyue_chest_pos_$floor', '${gridPos.x}_${gridPos.y}');
  }

  /// 按楼层获取宝箱位置
  static Future<Vector2?> getChestPosition(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('huanyue_chest_pos_$floor');
    if (raw == null) return null;

    final parts = raw.split('_');
    if (parts.length != 2) return null;

    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;

    return Vector2(x, y);
  }

  /// 标记宝箱为已开启
  static Future<void> markChestOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final opened = prefs.getStringList('huanyue_opened_chests') ?? [];
    if (!opened.contains(id)) {
      opened.add(id);
      await prefs.setStringList('huanyue_opened_chests', opened);
    }
  }

  /// 判断宝箱是否已开启
  static Future<bool> isChestOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final opened = prefs.getStringList('huanyue_opened_chests') ?? [];
    return opened.contains(id);
  }

  /// 📥 获取当前所在的幻月宫楼层（默认第1层）
  static Future<int> getFloor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_floorKey) ?? 1;
  }

  /// 📤 设置幻月宫当前层数
  static Future<void> setFloor(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_floorKey, floor);
  }

  static Future<void> saveDoorPosition(int floor, Vector2 pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huanyue_door_pos_$floor', '${pos.x}_${pos.y}');
  }

  static Future<Vector2?> getDoorPosition(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('huanyue_door_pos_$floor');
    if (str == null) return null;
    final parts = str.split('_');
    return Vector2(
      double.tryParse(parts[0]) ?? 0,
      double.tryParse(parts[1]) ?? 0,
    );
  }

  static Future<void> clearDoorPosition(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('huanyue_door_pos_$floor');
  }

  static Future<void> saveEnemyPosition(String id, Vector2 tilePos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('enemyPositions') ?? '{}';
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    data[id] = '${tilePos.x.toInt()}_${tilePos.y.toInt()}';
    await prefs.setString('enemyPositions', jsonEncode(data));
  }

  static Future<Vector2?> getEnemyPosition(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('enemyPositions') ?? '{}';
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    if (!data.containsKey(id)) return null;
    final parts = data[id].split('_');
    return Vector2(
      double.tryParse(parts[0]) ?? 0,
      double.tryParse(parts[1]) ?? 0,
    );
  }

  /// 判断当前楼层所有怪物是否已击杀
  static Future<bool> areAllEnemiesKilled(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('enemyPositions') ?? '{}';
    final allPos = Map<String, dynamic>.from(jsonDecode(raw));

    final idsForFloor = allPos.keys
        .where((id) =>
    id.startsWith('enemy-$floor-') || id == 'boss-floor-$floor')
        .toList();

    for (final id in idsForFloor) {
      if (!await isEnemyKilled(id)) return false;
    }

    return true;
  }

  /// 判断当前楼层宝箱是否打开
  static Future<bool> isCurrentFloorChestOpened(int floor) async {
    final pos = await getChestPosition(floor);
    if (pos == null) return true; // 说明当前楼层本来就没有宝箱
    final chestId = '${floor}_${pos.x.toInt()}_${pos.y.toInt()}';
    return await isChestOpened(chestId);
  }

}
