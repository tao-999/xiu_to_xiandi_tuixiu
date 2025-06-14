import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class ZongmenStorage {
  static const String _zongmenKey = 'current_zongmen';

  static const int _base = 500;
  static const double _power = 3.0;

  /// 📥 读取宗门（不含弟子）
  static Future<Zongmen?> loadZongmen() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_zongmenKey);
    if (jsonStr == null) return null;
    final map = json.decode(jsonStr);
    return Zongmen.fromMap(map);
  }

  /// 💾 保存宗门（不含弟子）
  static Future<void> saveZongmen(Zongmen zongmen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zongmenKey, json.encode(zongmen.toMap()));
  }

  /// 📤 加载弟子 + 更新年龄（Hive 读取）
  static Future<List<Disciple>> loadDisciples() async {
    final box = await Hive.openBox<Disciple>('disciples');
    print("📦 当前弟子总数（含未加入宗门的）: ${box.length}");

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeRate = 10000; // 时间倍率

    final List<Disciple> zongmenDisciples = [];

    for (final d in box.values) {
      // 只处理已加入宗门的弟子
      if (d.joinedAt == null) continue;

      final passed = (now - d.joinedAt!) * timeRate;
      final years = (passed / (3600 * 24 * 365)).floor();

      // 更新年龄（仅当年纪成长了才保存）
      if (years > d.age) {
        final newD = d.copyWith(age: years);
        await box.put(newD.id, newD);
        zongmenDisciples.add(newD);
      } else {
        zongmenDisciples.add(d);
      }
    }

    print("✅ 加载的宗门弟子数量：${zongmenDisciples.length}");
    return zongmenDisciples;
  }

  static Future<void> addDisciple(Disciple d) async {
    final box = await Hive.openBox<Disciple>('disciples');
    if (!box.containsKey(d.id)) {
      await box.put(d.id, d);
    }
  }

  static Future<void> removeDisciple(Disciple d) async {
    final box = await Hive.openBox<Disciple>('disciples');
    await box.delete(d.id);
  }

  static Future<void> setDiscipleAssignedRoom(String discipleId, String room) async {
    final box = await Hive.openBox<Disciple>('disciples');

    for (final d in box.values) {
      if (d.id == discipleId) {
        await box.put(d.id, d.copyWith(assignedRoom: room));
      } else if (d.assignedRoom == room) {
        await box.put(d.id, d.copyWith(assignedRoom: null));
      }
    }
  }

  static Future<void> removeDiscipleFromRoom(String discipleId, String room) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final d = box.get(discipleId);
    if (d != null && d.assignedRoom == room) {
      await box.put(d.id, d.copyWith(assignedRoom: null));
    }
  }

  static Future<List<Disciple>> getDisciplesByRoom(String room) async {
    final box = await Hive.openBox<Disciple>('disciples');
    return box.values.where((d) => d.assignedRoom == room).toList();
  }

  static Future<void> clearRoomAssignments(String room) async {
    final box = await Hive.openBox<Disciple>('disciples');
    for (final d in box.values) {
      if (d.assignedRoom == room) {
        await box.put(d.id, d.copyWith(assignedRoom: null));
      }
    }
  }

  /// 🧮 宗门等级系统

  static int requiredExp(int level) {
    if (level <= 1) return 0;
    return (_base * pow(level, _power)).toInt();
  }

  static int calcSectLevel(int exp) {
    var lvl = 1;
    while (requiredExp(lvl + 1) <= exp) {
      lvl++;
    }
    return lvl;
  }

  static int nextLevelRequiredExp(int currentExp) {
    final lvl = calcSectLevel(currentExp);
    return requiredExp(lvl + 1);
  }

  static Future<Zongmen> addSectExp(Zongmen zongmen, int delta) async {
    final newExp = zongmen.sectExp + delta;
    final newZongmen = zongmen.copyWith(sectExp: newExp);
    await saveZongmen(newZongmen);
    return newZongmen;
  }
}
