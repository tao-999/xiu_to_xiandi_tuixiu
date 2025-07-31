import 'package:shared_preferences/shared_preferences.dart';

class MenuStateService {
  static const _keyExpanded = 'menu_expanded';

  /// 保存菜单展开状态
  static Future<void> saveExpandedState(bool isExpanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpanded, isExpanded);
  }

  /// 读取菜单展开状态，默认为 true
  static Future<bool> loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpanded) ?? true;
  }
}
