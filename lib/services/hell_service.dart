import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/components.dart';
import '../widgets/components/hell_monster_component.dart';
import '../models/hell_game_state.dart'; // ✅ 加入新模型

class HellService {
  static const _monsterListKey = 'hell_alive_monsters';
  static const _bossKey = 'hell_boss_monster';
  static const _rewardKey = 'hell_earned_spirit_stone_mid';
  static const _playerKey = 'hell_player_info';

  // ✅ 保存基础状态
  static Future<void> saveState({
    required int killed,
    required bool bossSpawned,
    required int spawned,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prevSpawned = prefs.getInt('hell_spawned_count') ?? 0;
    final newSpawned = max(prevSpawned, spawned); // ✅ 保底不回退
    await prefs.setInt('hell_killed', killed);
    await prefs.setBool('hell_boss_spawned', bossSpawned);
    await prefs.setInt('hell_spawned_count', newSpawned);
  }

  // ✅ 加载状态为结构体
  static Future<HellGameState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('hell_killed')) return null;

    return HellGameState(
      killed: prefs.getInt('hell_killed') ?? 0,
      bossSpawned: prefs.getBool('hell_boss_spawned') ?? false,
      spawned: prefs.getInt('hell_spawned_count') ?? 0,
    );
  }

  static Future<void> saveStateAndLog({
    required int killed,
    required bool bossSpawned,
    required int spawned,
  }) async {
    await saveState(killed: killed, bossSpawned: bossSpawned, spawned: spawned);
    debugPrint('📦 [HellService] saveState → 🧮 killed=$killed, 🧬 spawned=$spawned, 👹 boss=$bossSpawned');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hell_killed');
    await prefs.remove('hell_boss_spawned');
    await prefs.remove('hell_spawned_count');
    await prefs.remove(_monsterListKey);
    await prefs.remove(_bossKey);
    await prefs.remove(_playerKey);
  }

  static Future<void> saveAliveMonsters(List<HellMonsterComponent> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((m) => {
      'id': m.id,
      'level': m.level,
      'hp': m.hp,
      'maxHp': m.maxHp,
      'atk': m.atk,
      'def': m.def,
      'x': m.position.x,
      'y': m.position.y,
    }).toList();
    await prefs.setString(_monsterListKey, jsonEncode(jsonList));
  }

  static Future<List<Map<String, dynamic>>> loadAliveMonsters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monsterListKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveBossMonster(HellMonsterComponent boss) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'id': boss.id,
      'level': boss.level,
      'hp': boss.hp,
      'maxHp': boss.maxHp,
      'atk': boss.atk,
      'def': boss.def,
      'x': boss.position.x,
      'y': boss.position.y,
    });
    await prefs.setString(_bossKey, json);
  }

  static Future<Map<String, dynamic>?> loadBossMonster() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bossKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveSpiritStoneReward(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rewardKey, amount);
  }

  static Future<int> loadSpiritStoneReward() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_rewardKey) ?? 0;
  }

  static Future<void> savePlayerInfo({
    required Vector2 position,
    required int hp,
    required int maxHp,
    required int level,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'x': position.x,
      'y': position.y,
      'hp': hp,
      'maxHp': maxHp,
      'level': level,
    };
    await prefs.setString(_playerKey, jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> loadPlayerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> clearPlayerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerKey);
  }

  static Map<String, int> calculateMonsterAttributes({
    required int level,
    required bool isBoss,
  }) {
    final levelBonusAtk = (level - 1) * 300;
    final atk = isBoss ? 3000 : 1000 + levelBonusAtk;

    final levelBonusDef = (level - 1) * 150;
    final def = isBoss ? 1500 : 500 + levelBonusDef;

    final levelBonusHp = (level - 1) * 3000;
    final hp = isBoss ? 50000 : 10000 + levelBonusHp;

    return {
      'atk': atk,
      'def': def,
      'hp': hp,
    };
  }
}
