import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_material.dart';
import 'package:xiu_to_xiandi_tuixiu/data/all_refine_blueprints.dart';

import '../utils/lingshi_util.dart';

class RefineMaterialService {
  static const _storageKey = 'refine_material_inventory';

  /// 🔁 构建所有材料列表（levelForgeMaterials）
  static List<RefineMaterial> generateAllMaterials() {
    final List<RefineMaterial> result = [];

    for (int level = 1; level <= levelForgeMaterials.length; level++) {
      final materialNames = levelForgeMaterials[level - 1];

      for (final name in materialNames) {
        // 🧠 灵石类型与价格自动决定
        late final LingShiType type;
        late final int amount;

        if (level <= 5) {
          type = LingShiType.lower;
          amount = 1000 * level * level;
        } else if (level <= 10) {
          type = LingShiType.middle;
          amount = 100 * level * level;
        } else if (level <= 15) {
          type = LingShiType.upper;
          amount = 10 * level * level;
        } else {
          type = LingShiType.supreme;
          amount = level * level;
        }

        result.add(
          RefineMaterial(
            id: 'mat-$level-$name',
            name: name,
            level: level,
            image: 'assets/images/materials/$name.png',
            priceAmount: amount,
            priceType: type,
          ),
        );
      }
    }

    return result;
  }

  /// ✅ 获取指定阶材料
  static List<RefineMaterial> getMaterialsForLevel(int level) {
    return generateAllMaterials().where((m) => m.level == level).toList();
  }

  /// ✅ 通过材料名找材料对象
  static RefineMaterial? getByName(String name) {
    try {
      return generateAllMaterials().firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 📦 加载玩家拥有的材料数量
  static Future<Map<String, int>> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.map((k, v) => MapEntry(k, v as int));
  }

  /// 🔼 添加材料
  static Future<void> add(String name, int count) async {
    final inv = await _loadInventory();
    inv[name] = (inv[name] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(inv));
  }

  /// 🔍 查询材料数量
  static Future<int> getCount(String name) async {
    final inv = await _loadInventory();
    return inv[name] ?? 0;
  }

  static Future<Map<String, int>> loadInventory() => _loadInventory();
}
