import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class RoleService {
  static const String _regionBoxName = 'role_regions';
  static const String _roleBoxName = 'disciple_roles'; // ✅ 新增职位 box

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

  // ------------------ 职位存储 ------------------

  /// ✅ 保存弟子职位
  static Future<void> saveRole(String id, String? role) async {
    final box = await _openRoleBox();
    if (role == null || role.isEmpty) {
      await box.delete(id);
      debugPrint('🗑️ 已清除职位：$id');
    } else {
      await box.put(id, role);
      debugPrint('✅ 已保存职位：$id -> $role');
    }
  }

  /// ✅ 加载弟子职位
  static Future<String?> loadRole(String id) async {
    final box = await _openRoleBox();
    final role = box.get(id);
    return role is String ? role : null;
  }

  /// ✅ 一次性加载全部职位（Map<id, role>）
  static Future<Map<String, String>> loadAllRoles() async {
    final box = await _openRoleBox();
    final Map<String, String> result = {};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is String) {
        result[key] = value;
      }
    }
    return result;
  }

  /// ✅ 清空所有职位（调试用）
  static Future<void> clearAllRoles() async {
    final box = await _openRoleBox();
    await box.clear();
  }

  // ------------------ 私有辅助 ------------------

  static Future<Box> _openRegionBox() async {
    return await Hive.openBox(_regionBoxName);
  }

  static Future<Box> _openRoleBox() async {
    return await Hive.openBox(_roleBoxName);
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
}
