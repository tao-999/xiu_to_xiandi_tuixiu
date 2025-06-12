// lib/services/zongmen_storage.dart

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class ZongmenStorage {
  static const String _zongmenKey = 'current_zongmen';

  /// —— 幂次拟合参数 —— ///
  static const int _base = 500;
  static const double _power = 3.0;

  /// 读取当前宗门（只管经验和其他字段，不再读/写 level）
  static Future<Zongmen?> loadZongmen() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_zongmenKey);
    if (jsonStr == null) return null;

    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return Zongmen.fromMap(map);
  }

  /// 保存当前宗门（不再带 level）
  static Future<void> saveZongmen(Zongmen zongmen) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(zongmen.toMap());
    await prefs.setString(_zongmenKey, jsonStr);
  }

  /// 弟子列表读取 & 年龄更新同上
  static Future<List<Disciple>> loadDisciples() async {
    final z = await loadZongmen();
    if (z == null) return [];
    final updated = z.disciples.map(_updateDiscipleAge).toList();
    await saveDisciples(updated);
    return updated;
  }

  static Future<void> saveDisciples(List<Disciple> list) async {
    final z = await loadZongmen();
    if (z == null) return;
    final updated = z.copyWith(disciples: list);
    await saveZongmen(updated);
  }

  static Future<void> addDisciple(Disciple d) async {
    final list = await loadDisciples();
    if (list.any((x) => x.id == d.id)) return;
    list.add(d);
    await saveDisciples(list);
  }

  static Future<void> removeDisciple(Disciple d) async {
    final list = await loadDisciples();
    list.removeWhere((x) => x.id == d.id);
    await saveDisciples(list);
  }

  static Disciple _updateDiscipleAge(Disciple d) {
    if (d.joinedAt == null) return d;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeRate = 10000;
    final passed = (now - d.joinedAt!) * timeRate;
    final years = (passed / (3600 * 24 * 365)).floor();
    return years > d.age ? d.copyWith(age: years) : d;
  }

  /// 计算达到 [level] 所需的【累计】宗门经验
  static int requiredExp(int level) {
    if (level <= 1) return 0;
    return (_base * pow(level, _power)).toInt();
  }

  /// 根据当前经验计算对应等级
  static int calcSectLevel(int exp) {
    var lvl = 1;
    while (requiredExp(lvl + 1) <= exp) {
      lvl++;
    }
    return lvl;
  }

  /// 查询当前经验下，升到下一等级所需的累计经验
  static int nextLevelRequiredExp(int currentExp) {
    final lvl = calcSectLevel(currentExp);
    return requiredExp(lvl + 1);
  }

  /// 给宗门增加经验，自动保存并返回最新对象
  static Future<Zongmen> addSectExp(Zongmen zongmen, int delta) async {
    final newExp = zongmen.sectExp + delta;
    final newZongmen = zongmen.copyWith(sectExp: newExp);
    await saveZongmen(newZongmen);
    return newZongmen;
  }
}
