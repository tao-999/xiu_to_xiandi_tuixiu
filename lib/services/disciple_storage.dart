import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class DiscipleStorage {
  static const _key = 'recruited_disciples';

  /// 获取所有已招募弟子
  static Future<List<Disciple>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => Disciple.fromMap(e)).toList();
  }

  /// 添加新弟子
  static Future<void> addAll(List<Disciple> list) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAll();
    final updated = [...existing, ...list];
    final encoded = json.encode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  /// 更新某个弟子（根据 id 匹配）
  static Future<void> update(Disciple d) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    final updated = list.map((e) => e.id == d.id ? d : e).toList();
    final encoded = json.encode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  /// 删除某个弟子（根据 id 匹配）
  static Future<void> removeById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    final updated = list.where((e) => e.id != id).toList();
    final encoded = json.encode(updated.map((e) => e.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  /// 清空所有弟子
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
