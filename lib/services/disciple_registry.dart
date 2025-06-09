import 'package:shared_preferences/shared_preferences.dart';

class DiscipleRegistry {
  static const String _key = 'owned_aptitudes';

  /// ✅ 记录某资质被招募过
  static Future<void> markOwned(int aptitude) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key)?.toSet() ?? {};
    existing.add(aptitude.toString());
    await prefs.setStringList(_key, existing.toList());
  }

  /// ✅ 获取所有被招募过的资质
  static Future<Set<int>> loadOwned() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map(int.parse).toSet();
  }

  /// 🧼 清除图鉴（调试用）
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
