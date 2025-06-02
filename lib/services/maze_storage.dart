import 'dart:convert';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MazeStorage {
  static const _playerPosKey = 'maze_player_pos';
  static const _killedEnemiesKey = 'maze_killed_enemies';
  static const _chestOpenedKey = 'maze_chest_opened';
  static const _chestPositionKey = 'maze_chest_position';
  static const _killedEnemyIdsKey = 'maze_killed_ids';
  static const String _openedChestIdsKey = 'opened_chest_ids';

  /// ✅ 保存玩家位置
  static Future<void> savePlayerPosition(Vector2 pos) async {
    final prefs = await SharedPreferences.getInstance();
    final str = '${pos.x.toInt()}_${pos.y.toInt()}';
    await prefs.setString(_playerPosKey, str);
  }

  /// ✅ 读取玩家位置
  static Future<Vector2?> getPlayerPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_playerPosKey);
    if (str == null) return null;

    final parts = str.split('_');
    return Vector2(
      double.tryParse(parts[0]) ?? 0,
      double.tryParse(parts[1]) ?? 0,
    );
  }

  /// ✅ 记录击杀的敌人位置
  static Future<void> markEnemyKilled(Vector2 tilePos) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('killedEnemies') ?? [];
    final id = '${tilePos.x.toInt()}_${tilePos.y.toInt()}';
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList('killedEnemies', list.toSet().toList());
    }
  }

  /// ✅ 读取所有已击杀敌人坐标
  static Future<List<Vector2>> getKilledEnemies() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('killedEnemies') ?? [];
    return list.map((s) {
      final parts = s.split('_');
      return Vector2(
        double.tryParse(parts[0]) ?? 0,
        double.tryParse(parts[1]) ?? 0,
      );
    }).toList();
  }

  static Future<bool> isEnemyKilled(Vector2 tilePos) async {
    final id = '${tilePos.x.toInt()}_${tilePos.y.toInt()}';
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('killedEnemies') ?? [];
    return list.contains(id);
  }

  static Future<void> clearKilledEnemies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('killedEnemies');
  }

  static Future<void> markEnemyKilledById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_killedEnemyIdsKey) ?? [];
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_killedEnemyIdsKey, list);
    }
  }

  static Future<List<String>> getKilledEnemyIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_killedEnemyIdsKey) ?? [];
  }

  /// ✅ 标记宝箱是否已开启
  static Future<void> markChestOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_openedChestIdsKey) ?? [];
    if (!raw.contains(id)) {
      raw.add(id);
      await prefs.setStringList(_openedChestIdsKey, raw);
    }
  }

  /// ✅ 查询宝箱是否已开启
  static Future<bool> isChestOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_openedChestIdsKey) ?? [];
    return raw.contains(id);
  }

  // ✅ 保存宝箱的坐标
  static Future<void> setChestPosition(Vector2 pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_chestPositionKey}_x', pos.x);
    await prefs.setDouble('${_chestPositionKey}_y', pos.y);
  }

  // ✅ 读取宝箱的坐标
  static Future<Vector2?> getChestPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('${_chestPositionKey}_x');
    final y = prefs.getDouble('${_chestPositionKey}_y');
    if (x != null && y != null) {
      return Vector2(x, y);
    }
    return null;
  }

  // ✅ 重置宝箱状态（如果需要在通关或退出时重置）
  static Future<void> resetChestState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chestOpenedKey);
    await prefs.remove('${_chestPositionKey}_x');
    await prefs.remove('${_chestPositionKey}_y');
    // ✅ 还要清除 UUID 开启记录列表
    await prefs.remove('opened_chest_ids');
  }

  /// ✅ 清除所有迷宫数据
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerPosKey);
    await prefs.remove(_killedEnemiesKey);
    await prefs.remove(_chestOpenedKey);
  }

  // MazeStorage.dart 中新增 👇

  static Future<void> saveMazeGrid(List<List<int>> grid) async {
    final flat = grid.expand((row) => row).toList();
    final rows = grid.length;
    final cols = grid[0].length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('maze_grid', flat.map((e) => e.toString()).toList());
    await prefs.setInt('maze_grid_rows', rows);
    await prefs.setInt('maze_grid_cols', cols);
  }

  static Future<List<List<int>>?> loadMazeGrid() async {
    final prefs = await SharedPreferences.getInstance();
    final flatList = prefs.getStringList('maze_grid');
    final rows = prefs.getInt('maze_grid_rows');
    final cols = prefs.getInt('maze_grid_cols');

    if (flatList == null || rows == null || cols == null) return null;
    final flatInt = flatList.map(int.parse).toList();
    return List.generate(rows, (y) => flatInt.sublist(y * cols, (y + 1) * cols));
  }

  /// ✅ 保存入口坐标
  static Future<void> saveEntry(Vector2 entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maze_entry_x', entry.x);
    await prefs.setDouble('maze_entry_y', entry.y);
  }

  /// ✅ 保存出口坐标
  static Future<void> saveExit(Vector2 exit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maze_exit_x', exit.x);
    await prefs.setDouble('maze_exit_y', exit.y);
  }

  /// ✅ 读取入口坐标（没有就返回 null）
  static Future<Vector2?> loadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('maze_entry_x');
    final y = prefs.getDouble('maze_entry_y');
    if (x == null || y == null) return null;
    return Vector2(x, y);
  }

  /// ✅ 读取出口坐标（没有就返回 null）
  static Future<Vector2?> loadExit() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('maze_exit_x');
    final y = prefs.getDouble('maze_exit_y');
    if (x == null || y == null) return null;
    return Vector2(x, y);
  }

  static Future<void> saveCurrentFloor(int floor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maze_current_floor', floor);
  }

  static Future<int> loadCurrentFloor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('maze_current_floor') ?? 1; // 默认为第1层
  }

  static Future<void> saveMaze(List<List<int>> grid, Vector2 entry, Vector2 exit) async {
    await saveMazeGrid(grid);
    await saveEntry(entry);
    await saveExit(exit);
  }

  static Future<void> saveEnemyStates(List<EnemyState> states) async {
    final prefs = await SharedPreferences.getInstance();
    final list = states.map((e) => e.toJson()).toList();
    await prefs.setString('maze_enemy_states', jsonEncode(list));
  }

  static Future<List<EnemyState>> loadEnemyStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('maze_enemy_states');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EnemyState.fromJson(e)).toList();
  }

  static Future<bool> getChestOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('maze_chest_opened') ?? false;
  }

  static Future<void> clearAllMazeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('maze_grid');
    await prefs.remove('maze_entry');
    await prefs.remove('maze_exit');
    await prefs.remove('maze_enemy_states');
    await prefs.remove('maze_killed_enemies');
    await prefs.remove('maze_chest_opened');
    await prefs.remove('maze_player_position');
    await prefs.remove(_killedEnemyIdsKey); // ✅ 加上这句
  }

}

class EnemyState {
  final String id; // ✅ 新增 UUID
  final double x;
  final double y;
  final int hp;
  final int atk;
  final int def;
  final String spritePath;
  final bool isBoss;
  final int reward;

  EnemyState({
    required this.id,
    required this.x,
    required this.y,
    required this.hp,
    required this.atk,
    required this.def,
    required this.spritePath,
    required this.isBoss,
    required this.reward,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'hp': hp,
    'atk': atk,
    'def': def,
    'spritePath': spritePath,
    'isBoss': isBoss,
    'reward': reward,
  };

  factory EnemyState.fromJson(Map<String, dynamic> json) => EnemyState(
    id: json['id'], // ✅ 反序列化 ID
    x: json['x'],
    y: json['y'],
    hp: json['hp'],
    atk: json['atk'],
    def: json['def'],
    spritePath: json['spritePath'],
    isBoss: json['isBoss'],
    reward: json['reward'],
  );
}
