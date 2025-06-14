// lib/services/disciple_storage.dart

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/disciple.dart';

class DiscipleStorage {
  static const _boxName = 'disciples';
  static const _metaTotalKey = 'total_draws';
  static const _metaSSRKey = 'draws_until_ssr';
  static const _sortOptionKey = 'disciple_sort_option';

  static Future<Box<Disciple>> _openBox() async {
    return await Hive.openBox<Disciple>(_boxName);
  }

  static Future<void> save(Disciple d) async {
    final box = await _openBox();
    await box.put(d.id, d);
  }

  static Future<Disciple?> load(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  static Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  static Future<List<Disciple>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }

  static Future<void> saveAll(List<Disciple> list) async {
    final box = await _openBox();
    final Map<String, Disciple> map = {for (var d in list) d.id: d};
    await box.putAll(map);
  }

  static Future<void> clear() async {
    final box = await _openBox();
    print("清除前： ${box.length}"); // 打印当前盒子的长度
    await box.clear();
    print("清除后： ${box.length}");  // 打印清除后的长度
  }

  // 抽卡元数据
  static Future<int> getTotalDraws() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_metaTotalKey) ?? 0;
  }

  static Future<void> incrementTotalDraws(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_metaTotalKey) ?? 0;
    await prefs.setInt(_metaTotalKey, current + count);
  }

  static Future<int> getDrawsUntilSSR() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_metaSSRKey) ?? 80;
  }

  static Future<void> setDrawsUntilSSR(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_metaSSRKey, value.clamp(0, 80));
  }

  static Future<void> incrementDrawsUntilSSR(int count, {bool hitSSR = false}) async {
    if (hitSSR) return;
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_metaSSRKey) ?? 80;
    current -= count;
    if (current <= 0) current = 80;
    await prefs.setInt(_metaSSRKey, current);
  }

  // 排序选项
  static Future<void> saveSortOption(String option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOptionKey, option);
  }

  static Future<String> loadSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOptionKey) ?? 'time_desc';
  }
}
