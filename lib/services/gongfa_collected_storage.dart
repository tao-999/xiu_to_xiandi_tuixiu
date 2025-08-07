// 📂 lib/services/gongfa_collected_storage.dart

import 'package:hive/hive.dart';
import '../models/gongfa.dart';

class GongfaCollectedStorage {
  static const _tileBoxName = 'collected_gongfa_box';
  static const _gongfaBoxName = 'collected_gongfa_data_box';

  static Box<bool>? _tileBox;
  static Box<Gongfa>? _gongfaBox;

  // ======================== tileKey 拾取状态 ======================== //

  static Future<Box<bool>> _getTileBox() async {
    if (_tileBox != null && _tileBox!.isOpen) return _tileBox!;
    _tileBox = await Hive.openBox<bool>(_tileBoxName);
    return _tileBox!;
  }

  static Future<void> markCollected(String tileKey) async {
    final box = await _getTileBox();
    await box.put(tileKey, true);
  }

  static Future<bool> isCollected(String tileKey) async {
    final box = await _getTileBox();
    return box.get(tileKey, defaultValue: false) ?? false;
  }

  static Future<List<String>> getAllCollectedKeys() async {
    final box = await _getTileBox();
    return box.keys.cast<String>().toList();
  }

  static Future<void> clearCollectedKeys() async {
    final box = await _getTileBox();
    await box.clear();
  }

  // ======================== 功法存储（带数量） ======================== //

  static Future<Box<Gongfa>> _getGongfaBox() async {
    if (_gongfaBox != null && _gongfaBox!.isOpen) return _gongfaBox!;
    _gongfaBox = await Hive.openBox<Gongfa>(_gongfaBoxName);
    return _gongfaBox!;
  }

  /// ✅ 添加功法（id+level 相同 → 累加数量；否则新增）
  static Future<void> addGongfa(Gongfa newGongfa) async {
    final box = await _getGongfaBox();

    String? existingKey;
    for (final key in box.keys) {
      final g = box.get(key);
      if (g != null && g.id == newGongfa.id && g.level == newGongfa.level) {
        existingKey = key as String;
        break;
      }
    }

    if (existingKey != null) {
      final existing = box.get(existingKey)!;
      final updated = existing.copyWith(count: existing.count + newGongfa.count);
      await box.put(existingKey, updated);
    } else {
      final key = '${newGongfa.id}_${newGongfa.level}_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(key, newGongfa);
    }
  }

  /// 📦 获取所有功法
  static Future<List<Gongfa>> getAllGongfa() async {
    final box = await _getGongfaBox();
    return box.values.toList();
  }

  /// ❓ 获取指定功法（根据 id 和 level）
  static Future<Gongfa?> getGongfaByIdAndLevel(String id, int level) async {
    final box = await _getGongfaBox();
    for (final g in box.values) {
      if (g.id == id && g.level == level) return g;
    }
    return null;
  }

  /// 🗑 删除某个功法（根据 id 和 level）
  static Future<void> deleteGongfaByIdAndLevel(String id, int level) async {
    final box = await _getGongfaBox();

    String? targetKey;
    for (final key in box.keys) {
      final g = box.get(key);
      if (g != null && g.id == id && g.level == level) {
        targetKey = key as String;
        break;
      }
    }

    if (targetKey != null) {
      await box.delete(targetKey);
    }
  }

  /// 🧹 清空所有功法
  static Future<void> clearGongfa() async {
    final box = await _getGongfaBox();
    await box.clear();
  }
}
