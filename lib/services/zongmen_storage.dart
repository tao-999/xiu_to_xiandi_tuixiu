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
    if (zongmen == null) return [];

    // 🧙‍♂️ 年龄批量更新，防止时间倒流
    final updated = zongmen.disciples.map(_updateDiscipleAge).toList();

    // 🧼 保存回宗门（只更新 age，不需要动模型字段）
    await saveDisciples(updated);

    return updated;
  }

  /// 保存弟子列表回宗门（可配合增删弟子使用）
  static Future<void> saveDisciples(List<Disciple> list) async {
    final zongmen = await loadZongmen();
    if (zongmen == null) return;
    zongmen.disciples = list;
    await saveZongmen(zongmen);
  }

  /// 单独添加一个弟子进宗门
  static Future<void> addDisciple(Disciple d) async {
    final list = await loadDisciples();
    // 避免重复添加
    if (list.any((x) => x.id == d.id)) return;
    list.add(d);
    await saveDisciples(list);
  }

  /// 从宗门弟子列表中移除指定弟子
  static Future<void> removeDisciple(Disciple d) async {
    final list = await loadDisciples();
    list.removeWhere((x) => x.id == d.id); // 用唯一 ID 做比对
    await saveDisciples(list);
  }

  static Disciple _updateDiscipleAge(Disciple d) {
    if (d.joinedAt == null) return d;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // ⚡ 游戏时间加速：10000 倍
    const timeRate = 10000;
    final gameTimePassed = (now - d.joinedAt!) * timeRate;

    // 🧮 秒 → 年，取整
    final deltaYears = (gameTimePassed / (3600 * 24 * 365)).floor();

    // 🧼 如果当前 age 比应有年龄小，就补齐
    final shouldBeAge = d.age < deltaYears ? deltaYears : d.age;

    if (shouldBeAge > d.age) {
      return d.copyWith(age: shouldBeAge);
    }

    return d;
  }

}
