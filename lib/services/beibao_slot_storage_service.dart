import 'package:shared_preferences/shared_preferences.dart';

class BeibaoSlotStorageService {
  static const String _key = 'beibao_slot_count';
  static const int defaultCount = 10 * 14;

  static Future<int> getSlotCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? defaultCount;
  }

  static Future<void> setSlotCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }

  static Future<void> resetSlotCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static const String _unlockConfirmKey = 'beibao_grid_unlock_confirmed';
  // 新增：持久化二次弹框已确认
  static Future<bool> getUnlockConfirmed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unlockConfirmKey) ?? false;
  }

  static Future<void> setUnlockConfirmed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockConfirmKey, value);
  }
}
