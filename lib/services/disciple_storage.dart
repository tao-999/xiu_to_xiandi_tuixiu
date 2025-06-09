import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class DiscipleStorage {
  static const _key = 'recruited_disciples';
  static const _totalDrawsKey = 'total_draws'; // 记录总抽卡次数
  static const _drawsUntilSSRKey = 'draws_until_ssr'; // 保底抽卡次数

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

  /// 获取当前总抽卡次数
  static Future<int> getTotalDraws() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalDrawsKey) ?? 0;
  }

  /// 增加抽卡次数
  static Future<void> incrementTotalDraws(int count) async {
    final prefs = await SharedPreferences.getInstance();
    int total = prefs.getInt(_totalDrawsKey) ?? 0;
    total += count;
    await prefs.setInt(_totalDrawsKey, total);
  }

  /// 获取当前保底剩余次数
  static Future<int> getDrawsUntilSSR() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_drawsUntilSSRKey) ?? 80;
  }

  /// 直接设置保底剩余抽数（骚哥用的精准保底更新）
  static Future<void> setDrawsUntilSSR(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_drawsUntilSSRKey, value.clamp(0, 80)); // 限制范围避免负数或超出
  }

  /// 抽卡后更新保底剩余抽数（仅用于没中SSR时）
  static Future<void> incrementDrawsUntilSSR(int count, {bool hitSSR = false}) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_drawsUntilSSRKey) ?? 80;

    if (!hitSSR) {
      current -= count;
      if (current <= 0) current = 80; // 到0保底自动触发，重置
      await prefs.setInt(_drawsUntilSSRKey, current);
    }

    // 如果 hitSSR 为 true，则不处理（你应该用 setDrawsUntilSSR 外部控制）
  }
}
