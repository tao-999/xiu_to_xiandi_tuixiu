import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChiyanguStorage {
  static const _storageKey = 'chiyangu_state';

  /// ✅ 保存状态（深度 + 格子）
  static Future<void> save({
    required int depth,
    required Map<String, Map<String, dynamic>> cells,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'depth': depth,
      'cells': cells,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
    print('✅ [ChiyanguStorage] 保存成功，深度 $depth，格子数：${cells.length}');
  }

  /// ✅ 加载状态（null 表示无存档）
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final cells = decoded['cells'];
        if (cells is Map<String, dynamic>) {
          final validCells = <String, Map<String, dynamic>>{};
          for (final entry in cells.entries) {
            final key = entry.key;
            final value = entry.value;
            if (value is Map<String, dynamic> &&
                value.containsKey('type') &&
                value.containsKey('breakLevel')) {
              validCells[key] = value;
            } else {
              print('⚠️ 跳过非法格子数据: $key');
            }
          }
          return {
            'depth': decoded['depth'] ?? 0,
            'cells': validCells,
          };
        }
      }
    } catch (e) {
      print('❌ [ChiyanguStorage] 加载失败：$e');
    }

    return null;
  }

  /// ✅ 清除存档（调试用）
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('🧹 [ChiyanguStorage] 已清除存档');
  }

  /// ✅ 是否有存档（UI用）
  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }

  // ----------------------------------------------------
  // 🛠 以下为锄头系统逻辑
  // ----------------------------------------------------

  static const _keyPickaxeCount = 'pickaxe_count';
  static const _keyPickaxeLastRefill = 'pickaxe_last_refill';

  static const int maxPickaxe = 1000;
  static const Duration refillCooldown = Duration(minutes: 5);

  /// ✅ 获取当前锄头数量（自动计算离线恢复）
  static Future<int> getPickaxeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPickaxeCount) ?? maxPickaxe;
  }

  /// ✅ 设置锄头数量（用于定时器写入）
  static Future<void> setPickaxeCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPickaxeCount, count);
  }

  /// ✅ 获取最后恢复时间
  static Future<DateTime> getLastPickaxeRefillTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_keyPickaxeLastRefill) ?? DateTime.now().millisecondsSinceEpoch;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// ✅ 设置最后恢复时间
  static Future<void> setLastPickaxeRefillTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPickaxeLastRefill, time.millisecondsSinceEpoch);
  }

  /// ✅ 获取剩余倒计时
  static Future<Duration> getPickaxeRefillCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyPickaxeLastRefill);
    if (last == null) return Duration.zero;
    final next = last + refillCooldown.inMilliseconds;
    final diff = Duration(milliseconds: next - DateTime.now().millisecondsSinceEpoch);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// ✅ 离线自动恢复
  static Future<void> _autoRefillPickaxe(SharedPreferences prefs) async {
    int current = prefs.getInt(_keyPickaxeCount) ?? maxPickaxe;
    final last = prefs.getInt(_keyPickaxeLastRefill) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - last;

    if (current >= maxPickaxe) return;

    final refillCount = elapsed ~/ refillCooldown.inMilliseconds;
    if (refillCount > 0) {
      current = (current + refillCount).clamp(0, maxPickaxe);
      await prefs.setInt(_keyPickaxeCount, current);
      final newLast = last + refillCount * refillCooldown.inMilliseconds;
      await prefs.setInt(_keyPickaxeLastRefill, newLast);
    }
  }

  static Future<void> resetPickaxeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPickaxeCount, 100); // 初始锄头数
    await prefs.setInt(_keyPickaxeLastRefill, DateTime.now().millisecondsSinceEpoch); // 立即开始倒计时
    print('🧹 [ChiyanguStorage] 锄头系统已重置为100个');
  }

  static Future<void> consumePickaxe() async {
    final prefs = await SharedPreferences.getInstance();
    await _autoRefillPickaxe(prefs); // 这会确保先执行恢复逻辑
    final current = prefs.getInt(_keyPickaxeCount) ?? maxPickaxe;
    if (current > 0) {
      await prefs.setInt(_keyPickaxeCount, current - 1);
    }
  }

}
