// lib/services/player_storage.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';

import '../utils/cultivation_level.dart';
import 'cultivation_tracker.dart';

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

  /// 批量更新字段
  static Future<void> updateFields(Map<String, dynamic> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json.addAll(fields);
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

  /// 读取 playerData 中指定字段（返回 int，默认 0）
  static Future<int> getIntField(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    return (json[key] ?? 0) as int;
  }

  /// 泛型读取任意字段（可选）
  static Future<T?> getField<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    return json[key] as T?;
  }

  /// ✨ 通用战斗力计算（用于角色、怪物等）
  static int calculatePower({
    required int hp,
    required int atk,
    required int def,
  }) {
    return (hp * 0.4 + atk * 2 + def * 1.5).toInt();
  }

  /// 🌱 获取当前玩家的境界总层数（练气1重 = 1，筑基1重 = 10 ...）
  static Future<int> getCultivationLayer() async {
    final player = await getPlayer();
    if (player == null) return 1;
    return calculateCultivationLevel(player.cultivation).totalLayer;
  }

  static Future<double> getSizeMultiplier() async {
    final layer = await getCultivationLayer();
    return 2.0 + (layer - 1) * 0.02;
  }

  /// 💪 获取当前玩家尺寸倍率（如 2.0、2.2）
  static Future<void> addCultivationByStones({
    int low = 0,
    int mid = 0,
    int high = 0,
    int supreme = 0,
    void Function()? onUpdate,
  }) async {
    final player = await getPlayer();
    if (player == null) {
      onUpdate?.call();
      return;
    }

    final res = player.resources;

    if (res.spiritStoneLow < low ||
        res.spiritStoneMid < mid ||
        res.spiritStoneHigh < high ||
        res.spiritStoneSupreme < supreme) {
      debugPrint('灵石不足');
      onUpdate?.call();
      return;
    }

    // ✅ 扣除灵石
    res.spiritStoneLow -= low;
    res.spiritStoneMid -= mid;
    res.spiritStoneHigh -= high;
    res.spiritStoneSupreme -= supreme;

    await savePlayer(player);

    // ✅ 计算应加的修为
    final double addedExp = calculateAddedExp(
      low: low,
      mid: mid,
      high: high,
      supreme: supreme,
    ).toDouble();

    // ✅ 用新版：停止tick → 加修为 → 存 → 重启tick
    await CultivationTracker.safeAddExp(addedExp, onUpdate: onUpdate);
  }

  /// 根据各级灵石数量，计算预计可增加的修为
  static int calculateAddedExp({
    int low = 0,
    int mid = 0,
    int high = 0,
    int supreme = 0,
  }) {
    return low * 10 +
        mid * 100000 +
        high * 1000000000 +
        supreme * 10000000000000;
  }
}