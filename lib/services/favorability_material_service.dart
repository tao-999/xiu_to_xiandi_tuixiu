// lib/services/favorability_material_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FavorabilityMaterialService {
  static const _prefix = 'favorability_material_';

  /// 增加某个材料数量
  static Future<void> addMaterial(int index, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$index';
    final oldQty = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, oldQty + quantity);
  }

  /// 获取某个材料数量
  static Future<int> getMaterialQuantity(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$index';
    return prefs.getInt(key) ?? 0;
  }

  /// 消耗某个材料
  static Future<void> consumeMaterial(int index, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$index';
    final oldQty = prefs.getInt(key) ?? 0;
    final newQty = (oldQty - quantity).clamp(0, double.infinity).toInt();
    await prefs.setInt(key, newQty);
  }

  /// 🌟一次性获取全部材料库存（1~30）
  static Future<Map<int, int>> getAllMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, int> result = {};
    for (int i = 1; i <= 30; i++) {
      final key = '$_prefix$i';
      final qty = prefs.getInt(key) ?? 0;
      result[i] = qty;
    }
    return result;
  }
}
