import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/herb_material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/lingshi_util.dart';

import '../data/all_pill_recipes.dart';
import '../models/pill_blueprint.dart';

class HerbMaterialService {
  static const _storageKey = 'herb_material_inventory';

  /// 🧪 生成全部草药材料（每阶 5 个）
  static List<HerbMaterial> generateAllMaterials() {
    final List<HerbMaterial> result = [];

    for (int level = 1; level <= levelMaterials.length; level++) {
      final names = levelMaterials[level - 1];
      for (final name in names) {
        late final LingShiType type;
        late final int amount;

        if (level <= 5) {
          type = LingShiType.lower;
          amount = 400 * level; // 💰 更便宜的草本价格
        } else if (level <= 10) {
          type = LingShiType.middle;
          amount = 60 * level; // 💰 中品打对折
        } else if (level <= 15) {
          type = LingShiType.upper;
          amount = 6 * level; // 💰 更低上品成本
        } else {
          type = LingShiType.supreme;
          amount = (level ~/ 2).clamp(1, 999); // 💰 至尊最低1起步
        }

        result.add(HerbMaterial(
          id: 'herb-$level-$name',
          name: name,
          level: level,
          image: 'assets/images/herbs/$name.png',
          priceAmount: amount,
          priceType: type,
        ));
      }
    }

    return result;
  }

  /// ✅ 查询指定阶数的草药
  static List<HerbMaterial> getByLevel(int level) {
    return generateAllMaterials().where((m) => m.id.contains('herb-$level-')).toList();
  }

  /// ✅ 通过名字查草药
  static HerbMaterial? getByName(String name) {
    try {
      return generateAllMaterials().firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 📦 加载当前玩家草药持有情况
  static Future<Map<String, int>> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.map((k, v) => MapEntry(k, v as int));
  }

  /// ✅ 添加草药数量
  static Future<void> add(String name, int count) async {
    final inv = await _loadInventory();
    inv[name] = (inv[name] ?? 0) + count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(inv));
  }

  /// ✅ 获取某种草药数量
  static Future<int> getCount(String name) async {
    final inv = await _loadInventory();
    return inv[name] ?? 0;
  }

  /// ✅ 全部草药持有量
  static Future<Map<String, int>> loadInventory() => _loadInventory();

  static List<HerbMaterial> getMaterialsByBlueprint(int level, PillBlueprintType type) {
    final all = generateAllMaterials().where((m) => m.level == level).toList();

    if (all.length < 5) return [];

    final fixed = all.sublist(0, 2); // 前2固定
    final thirdIndex = switch (type) {
      PillBlueprintType.attack => 2,
      PillBlueprintType.defense => 3,
      PillBlueprintType.health => 4,
    };

    final extra = all[thirdIndex];
    return [...fixed, extra];
  }
}
