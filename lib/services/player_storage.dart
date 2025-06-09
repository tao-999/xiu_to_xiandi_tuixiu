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

  /// 新增：读取 BigInt 类型字段（默认 BigInt.zero）
  static Future<BigInt> getBigIntField(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    final value = json[key];
    return value != null ? BigInt.parse(value.toString()) : BigInt.zero;
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

  /// 💪 获取当前玩家尺寸倍率（如 2.0、2.2）
  static Future<double> getSizeMultiplier() async {
    final layer = await getCultivationLayer();
    return 2.0 + (layer - 1) * 0.02;
  }

  /// 💰 使用灵石提升修为（全面支持 BigInt）
  static Future<void> addCultivationByStones({
    BigInt? low,
    BigInt? mid,
    BigInt? high,
    BigInt? supreme,
    void Function()? onUpdate,
  }) async {
    final l = low ?? BigInt.zero;
    final m = mid ?? BigInt.zero;
    final h = high ?? BigInt.zero;
    final s = supreme ?? BigInt.zero;

    final player = await getPlayer();
    if (player == null) {
      onUpdate?.call();
      return;
    }

    final res = player.resources;

    if (res.spiritStoneLow < l ||
        res.spiritStoneMid < m ||
        res.spiritStoneHigh < h ||
        res.spiritStoneSupreme < s) {
      debugPrint('灵石不足');
      onUpdate?.call();
      return;
    }

    res.spiritStoneLow -= l;
    res.spiritStoneMid -= m;
    res.spiritStoneHigh -= h;
    res.spiritStoneSupreme -= s;

    await savePlayer(player);

    final double addedExp = calculateAddedExp(
      low: l,
      mid: m,
      high: h,
      supreme: s,
    ).toDouble();

    await CultivationTracker.safeAddExp(addedExp, onUpdate: onUpdate);
  }

  /// 根据各级灵石数量，计算预计可增加的修为（支持 BigInt）
  static BigInt calculateAddedExp({
    BigInt? low,
    BigInt? mid,
    BigInt? high,
    BigInt? supreme,
  }) {
    final l = low ?? BigInt.zero;
    final m = mid ?? BigInt.zero;
    final h = high ?? BigInt.zero;
    final s = supreme ?? BigInt.zero;

    return (l * BigInt.from(5) +
        m * BigInt.from(50000) +
        h * BigInt.from(500000000) +
        s * BigInt.from(5000000000000));
  }
}
