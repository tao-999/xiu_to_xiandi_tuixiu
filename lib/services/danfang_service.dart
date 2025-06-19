import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/models/herb_material.dart';

class DanfangService {
  static const _selectedBlueprintKey = 'danfang_selected_blueprint';
  static const _cooldownKey = 'danfang_cooldown_time';
  static const _herbInventoryKey = 'herb_material_inventory';

  // 🌿================ 选中丹方相关 ====================

  /// ✅ 保存当前选中的丹方
  static Future<void> saveSelectedBlueprint(PillBlueprint blueprint) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': blueprint.name,
      'level': blueprint.level,
      'type': blueprint.type.name,
      'description': blueprint.description,
      'effectValue': blueprint.effectValue,
      'iconPath': blueprint.iconPath,
    };
    await prefs.setString(_selectedBlueprintKey, jsonEncode(data));
  }

  /// ✅ 读取当前选中的丹方（若没有则返回 null）
  static Future<PillBlueprint?> loadSelectedBlueprint() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selectedBlueprintKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw);
      return PillBlueprint(
        name: map['name'],
        level: map['level'],
        type: PillBlueprintType.values.firstWhere((e) => e.name == map['type']),
        description: map['description'] ?? '',
        effectValue: map['effectValue'] ?? 0,
        iconPath: map['iconPath'],
      );
    } catch (e) {
      print('❌ 读取丹方失败: $e');
      return null;
    }
  }

  // 🕒================ 冷却时间相关 ====================

  /// ✅ 保存炼丹冷却结束时间
  static Future<void> saveCooldown(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cooldownKey, endTime.toIso8601String());
  }

  /// ✅ 读取冷却结束时间
  static Future<DateTime?> loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cooldownKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // 🧹================ 清理状态 ====================

  /// ✅ 清除所有炼丹状态
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedBlueprintKey);
    await prefs.remove(_cooldownKey);
    await prefs.remove(_herbInventoryKey);
  }

  // 📦================ 草药背包相关 ====================

  /// ✅ 加载草药持有情况
  static Future<Map<String, int>> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_herbInventoryKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.map((k, v) => MapEntry(k, v as int));
  }

  /// ✅ 获取某种草药的持有数量
  static Future<int> getCount(String herbName) async {
    final inv = await _loadInventory();
    return inv[herbName] ?? 0;
  }

  /// ✅ 添加草药
  static Future<void> addHerb(String herbName, int count) async {
    final inv = await _loadInventory();
    inv[herbName] = (inv[herbName] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_herbInventoryKey, jsonEncode(inv));
  }

  /// ✅ 获取全部草药数量（Map）
  static Future<Map<String, int>> getAllHerbCounts() => _loadInventory();
}
