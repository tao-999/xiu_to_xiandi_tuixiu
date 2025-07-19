import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';

import 'herb_material_service.dart';

class DanfangService {
  static const _selectedBlueprintKey = 'danfang_selected_blueprint';
  static const _cooldownKey = 'danfang_cooldown_time';
  static const _herbInventoryKey = 'herb_material_inventory';
  static const _selectedMaterialsKey = 'danfang_selected_materials';

  // =================== 🌿 丹方逻辑 ===================

  /// ✅ 保存选中的丹方
  static Future<void> saveSelectedBlueprint(PillBlueprint blueprint) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': blueprint.name,
      'level': blueprint.level,
      'type': blueprint.type.name,
      'description': blueprint.description ?? '',
      'effectValue': blueprint.effectValue ?? 0,
      'iconPath': blueprint.iconPath,
    };
    await prefs.setString(_selectedBlueprintKey, jsonEncode(data));
  }

  /// ✅ 读取选中的丹方（若没有则返回 null）
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

  static Future<void> clearSelectedBlueprint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedBlueprintKey);
  }

  // =================== 🍀 草药选中逻辑 ===================

  static Future<void> saveSelectedMaterials(List<String> mats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMaterialsKey, jsonEncode(mats));
  }

  static Future<List<String>?> loadSelectedMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selectedMaterialsKey);
    if (raw == null) return null;
    return List<String>.from(jsonDecode(raw));
  }

  static Future<void> clearSelectedMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedMaterialsKey);
  }

  // =================== ⏳ 冷却时间 ===================

  static Future<void> saveCooldown(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cooldownKey, endTime.toIso8601String());
  }

  static Future<DateTime?> loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cooldownKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> clearCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cooldownKey);
  }

  /// 【修仙派】炼丹时间计算：1阶 300秒起步，每阶+60秒，资质越高越快（最多75%缩短）
  static int calculateRefineDuration(int level, int totalAptitude) {
    final baseTime = 30 + (level - 1) * 60;
    final aptitudeFactor = (1 - (totalAptitude / 999) * 0.95).clamp(0.05, 1.0);
    return (baseTime * aptitudeFactor).round();
  }

  // =================== 📦 草药背包 ===================

  static Future<Map<String, int>> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_herbInventoryKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.map((k, v) => MapEntry(k, v as int));
  }

  static Future<int> getCount(String herbName) async {
    final inv = await _loadInventory();
    return inv[herbName] ?? 0;
  }

  static Future<void> addHerb(String herbName, int count) async {
    final inv = await _loadInventory();
    inv[herbName] = (inv[herbName] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_herbInventoryKey, jsonEncode(inv));
  }

  static Future<Map<String, int>> getAllHerbCounts() => _loadInventory();

  static Future<void> clearInventory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_herbInventoryKey);
  }

  // =================== 🧹 状态清理 ===================

  /// ✅ 全部清除（慎用！）
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedBlueprintKey);
    await prefs.remove(_cooldownKey);
    await prefs.remove(_herbInventoryKey);
    await prefs.remove(_selectedMaterialsKey);
  }

  static const String _refineCountKey = 'danfangRefineCount';

  static Future<void> saveRefineCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refineCountKey, count);
  }

  static Future<int> loadRefineCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refineCountKey) ?? 1; // 默认炼1颗
  }

  static Future<void> clearRefineCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refineCountKey);
  }

  /// ✅ 消耗草药（炼制 N 个丹药）
  static Future<void> consumeHerbs(List<String> materialNames, int count) async {
    for (final name in materialNames) {
      final old = await HerbMaterialService.getCount(name);
      final newCount = (old - count).clamp(0, double.infinity).toInt();
      await HerbMaterialService.add(name, newCount - old); // 减法是 add 负值
    }
  }

  /// ✅ 获取最多可炼制数量（取草药最少那个）
  static Future<int> getMaxAlchemyCount(List<String> selectedMaterials) async {
    if (selectedMaterials.length < 3 || selectedMaterials.any((e) => e.isEmpty)) return 1;

    final counts = await Future.wait(
      selectedMaterials.map((name) => HerbMaterialService.getCount(name)),
    );

    return counts.reduce((a, b) => a < b ? a : b); // 取最小
  }

  static const String _keyIsRefining = 'danfang_is_refining';

  static Future<void> saveRefiningState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRefining, value);
  }

  static Future<bool> loadRefiningState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsRefining) ?? false;
  }
}
