import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';
import '../widgets/components/hell_monster_component.dart';

class HellService {
  static const _key = 'hell_state';

  /// 💾 保存当前地狱状态
  static Future<void> save({
    required int level,
    required int currentWave,
    required int totalWaves,
    required int currentAlive,
    required Vector2 playerPosition,
    required int playerHp,
    required int playerMaxHp,
    required List<HellMonsterComponent> monsters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'level': level,
      'currentWave': currentWave,
      'totalWaves': totalWaves,
      'currentAlive': currentAlive,
      'player': {
        'x': playerPosition.x,
        'y': playerPosition.y,
        'hp': playerHp,
        'maxHp': playerMaxHp,
      },
      'monsters': monsters.map((m) => {
        'id': m.id,
        'isBoss': m.isBoss,
        'level': m.level,
        'waveIndex': m.waveIndex,
        'x': m.position.x,
        'y': m.position.y,
        'hp': m.hp,
        'maxHp': m.maxHp,
        'atk': m.atk,
        'def': m.def,
      }).toList(),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  /// 📥 读取上次保存的状态（如无返回 null）
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// 🔥 清除当前保存的状态
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 🧪 检查是否已有保存
  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  static const _rewardKey = 'hell_earned_spirit_stone_mid';

  static Future<void> saveSpiritStoneReward(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rewardKey, amount);
  }

  static Future<int> loadSpiritStoneReward() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_rewardKey) ?? 0;
  }

  static Future<void> clearSpiritStoneReward() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rewardKey);
  }

}
