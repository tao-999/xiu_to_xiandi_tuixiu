import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_material.dart';
import 'package:xiu_to_xiandi_tuixiu/data/all_refine_blueprints.dart';

import '../models/disciple.dart';
import '../models/refine_blueprint.dart';
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

  /// ⏱ 获取炼制时间（分钟），如果没弟子就返回 null
  static Future<Duration?> getRefineDuration(int level, {Disciple? zhushou}) async {
    // 🧱 基础时间：300秒 + 每阶60秒，随着阶数增长
    final int baseSeconds = 300 + level * 60;

    if (zhushou == null) return null; // 没弟子？你想屁吃

    // ✅ 只限制最低资质为30，最高不设限
    final int aptitude = zhushou.aptitude < 30 ? 30 : zhushou.aptitude;

    // 🎯 资质越高，时间越短（无限上升，但保持正数）
    final double reductionFactor = 1 / (aptitude / 30); // 资质越高，分母越大 → 趋近于0

    // ⏱️ 最终时间（控制最短60秒，最长3600秒）
    final int finalSeconds = (baseSeconds * reductionFactor).clamp(60, 3600).round();

    // 🧾 打印骚日志
    print('🧪 [炼制时间计算 - 无上限模式]');
    print('📊 阶数: $level');
    print('🧬 资质: $aptitude');
    print('⏳ 基础时间: $baseSeconds 秒');
    print('⚡ 缩减比例: ${reductionFactor.toStringAsFixed(3)}');
    print('⏱️ 最终时间: $finalSeconds 秒');

    return Duration(seconds: finalSeconds);
  }


  // 🔐 持久化炼制状态键名
  static const _refineStateKey = 'refine_state';

  /// 🧪 保存炼制状态
  static Future<void> saveRefineState({
    required DateTime endTime,
    required RefineBlueprint blueprint,
    required List<String> selectedMaterials,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'endTime': endTime.toIso8601String(), // ✅ 直接存结束时间
      'blueprintName': blueprint.name,
      'blueprintLevel': blueprint.level,
      'blueprintType': blueprint.type.name,
      'materials': selectedMaterials,
    };

    await prefs.setString(_refineStateKey, jsonEncode(data));
    print('💾 已保存炼器状态：$data');
  }

  /// 🧪 读取炼制状态（若无则返回 null）
  static Future<Map<String, dynamic>?> loadRefineState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_refineStateKey);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// 🧪 清除炼制状态
  static Future<void> clearRefineState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refineStateKey);
  }

  static Future<Map<String, int>> loadInventory() => _loadInventory();

  /// ✅ 删除材料（彻底移除）
  static Future<void> remove(String name) async {
    final inv = await _loadInventory();
    inv.remove(name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(inv));
  }
}
