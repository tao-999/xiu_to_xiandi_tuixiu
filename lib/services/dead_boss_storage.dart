import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dead_boss_entry.dart';

class DeadBossStorage {
  static const _boxName = 'dead_boss_box';
  static Box<DeadBossEntry>? _box;

  /// 📦 获取 Hive Box
  static Future<Box<DeadBossEntry>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(DeadBossEntryAdapter());
    }
    _box = await Hive.openBox<DeadBossEntry>(_boxName);
    return _box!;
  }

  /// 💀 记录死亡 Boss 信息（唯一入口）
  static Future<void> markDeadBoss({
    required String tileKey,
    required Vector2 position,
    required String bossType,
    required Vector2 size,
  }) async {
    final box = await _getBox();
    final entry = DeadBossEntry(
      tileKey: tileKey,
      x: position.x,
      y: position.y,
      bossType: bossType,
      width: size.x,
      height: size.y,
    );
    await box.put(tileKey, entry);
  }

  /// ☠️ 是否死亡（通过 tileKey）
  static Future<bool> isDead(String tileKey) async {
    final box = await _getBox();
    return box.containsKey(tileKey);
  }

  /// 📍 获取死亡坐标（通过 tileKey）
  static Future<Vector2?> getDeathPosition(String tileKey) async {
    final box = await _getBox();
    final entry = box.get(tileKey);
    if (entry == null) return null;
    return Vector2(entry.x, entry.y);
  }

  /// 🎭 获取死亡 Boss 类型（通过 tileKey）
  static Future<String?> getBossType(String tileKey) async {
    final box = await _getBox();
    return box.get(tileKey)?.bossType;
  }

  /// 📏 获取死亡 Boss 尺寸（通过 tileKey）
  static Future<Vector2?> getBossSize(String tileKey) async {
    final box = await _getBox();
    final entry = box.get(tileKey);
    if (entry == null) return null;
    return Vector2(entry.width, entry.height);
  }

  /// 🎭 通过坐标反查 Boss 类型（非 tileKey）
  static Future<String?> getBossTypeByPosition(Vector2 pos) async {
    final box = await _getBox();
    for (final entry in box.values) {
      if (entry.x == pos.x && entry.y == pos.y) {
        return entry.bossType;
      }
    }
    return null;
  }

  /// 📏 通过坐标反查 Boss 尺寸（非 tileKey）
  static Future<Vector2?> getBossSizeByPosition(Vector2 pos) async {
    final box = await _getBox();
    for (final entry in box.values) {
      if (entry.x == pos.x && entry.y == pos.y) {
        return Vector2(entry.width, entry.height);
      }
    }
    return null;
  }

  /// 📋 获取所有死亡 Boss 信息（tileKey → 坐标）
  static Future<Map<String, Vector2>> getAllDeathEntries() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/dead_boss_box.hive');

    // ✅ 文件不存在就直接返回空 map
    if (!file.existsSync()) {
      debugPrint('[DeadBossStorage] ⚠️ dead_boss_box.hive 不存在，跳过加载');
      return {};
    }

    final box = await _getBox();
    return {
      for (final entry in box.values)
        entry.tileKey: Vector2(entry.x, entry.y),
    };
  }


  /// 🧹 清空所有记录（开发调试用）
  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
