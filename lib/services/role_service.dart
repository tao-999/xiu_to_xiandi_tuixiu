import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import 'disciple_storage.dart';

class RoleService {
  static const String _regionBoxName = 'role_regions';

  // ------------------ 坐标存储 ------------------

  static Future<void> saveRegion(String id, Rect region) async {
    final box = await _openRegionBox();
    box.put(id, _rectToMap(region));
  }

  static Future<Rect?> loadRegion(String id) async {
    final box = await _openRegionBox();
    final data = box.get(id);
    if (data is Map) {
      return _mapToRect(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<Map<String, Rect>> loadAllRegions() async {
    final box = await _openRegionBox();
    final Map<String, Rect> result = {};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final rect = _mapToRect(Map<String, dynamic>.from(value));
        if (rect != null) {
          result[key] = rect;
        }
      }
    }
    return result;
  }

  static Future<void> clearAllRegions() async {
    final box = await _openRegionBox();
    await box.clear();
  }

  // ------------------ 私有辅助 ------------------

  static Future<Box> _openRegionBox() async {
    return await Hive.openBox(_regionBoxName);
  }

  static Map<String, dynamic> _rectToMap(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  static Rect? _mapToRect(Map<String, dynamic> map) {
    try {
      return Rect.fromLTWH(
        map['left'] as double,
        map['top'] as double,
        map['width'] as double,
        map['height'] as double,
      );
    } catch (_) {
      return null;
    }
  }

  static const Map<String, double> roleBonus = {
    '宗主夫人': 1.0,
    '长老': 0.5,
    '执事': 0.3,
  };

  /// ✅ 将角色加成叠加写入 disciple.extra 属性（不覆盖、不清除）
  static Future<void> updateDiscipleRoleBonus(
      String discipleId,
      String? oldRole,
      String? newRole,
      ) async {
    final d = await DiscipleStorage.load(discipleId);
    if (d == null) return;

    // ✅ 职位加成表
    final bonusMap = {
      '宗主夫人': (1.0, 1.0, 1.0),
      '长老': (0.5, 0.5, 0.5),
      '执事': (0.3, 0.3, 0.3),
      '弟子': (0.0, 0.0, 0.0),
      null: (0.0, 0.0, 0.0), // 🧤 null 也当作“弟子”
    };

    final oldBonus = bonusMap[oldRole] ?? (0.0, 0.0, 0.0);
    final newBonus = bonusMap[newRole] ?? (0.0, 0.0, 0.0);

    d.extraHp += newBonus.$1 - oldBonus.$1;
    d.extraAtk += newBonus.$2 - oldBonus.$2;
    d.extraDef += newBonus.$3 - oldBonus.$3;

    debugPrint('🔁 [职位更新] $oldRole → $newRole');
    debugPrint('💠 [变化] HP: ${(newBonus.$1 - oldBonus.$1) * 100}%, ATK: ${(newBonus.$2 - oldBonus.$2) * 100}%, DEF: ${(newBonus.$3 - oldBonus.$3) * 100}%');

    await DiscipleStorage.save(d);
  }

}
