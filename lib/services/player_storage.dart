// lib/services/player_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';

class PlayerStorage {
  static const _playerKey = 'playerData';

  /// 精准更新 playerData 中的单个字段（推荐方式）
  static Future<void> updateField(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json[key] = value;
    await prefs.setString(_playerKey, jsonEncode(json));
  }

  /// 获取整个 player 对象
  static Future<Character?> getPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey);
    if (raw == null) return null;
    return Character.fromJson(jsonDecode(raw));
  }

  /// 全量覆盖 playerData（慎用）
  static Future<void> savePlayer(Character player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerKey, jsonEncode(player.toJson()));
  }
}
