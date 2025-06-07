import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class ZongmenStorage {
  static const String _zongmenKey = 'current_zongmen';

  /// 读取当前宗门
  static Future<Zongmen?> loadZongmen() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_zongmenKey);
    if (jsonStr == null) return null;

    final map = json.decode(jsonStr);
    return Zongmen.fromMap(map);
  }

  /// 保存当前宗门
  static Future<void> saveZongmen(Zongmen zongmen) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(zongmen.toMap());
    await prefs.setString(_zongmenKey, jsonStr);
  }

  /// 模拟读取弟子列表（你可以独立存储弟子表）
  static Future<List<Disciple>> loadDisciples() async {
    final zongmen = await loadZongmen();
    return zongmen?.disciples ?? [];
  }

  /// 保存弟子列表回宗门（可配合增删弟子使用）
  static Future<void> saveDisciples(List<Disciple> list) async {
    final zongmen = await loadZongmen();
    if (zongmen == null) return;
    zongmen.disciples = list;
    await saveZongmen(zongmen);
  }
}
