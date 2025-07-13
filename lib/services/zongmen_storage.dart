import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

import '../services/resources_storage.dart';
import '../utils/sect_role_limits.dart';

class ZongmenStorage {
  static const String _zongmenKey = 'current_zongmen';

  /// 📥 读取宗门
  static Future<Zongmen?> loadZongmen() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_zongmenKey);
    if (jsonStr == null) return null;
    final map = json.decode(jsonStr);
    return Zongmen.fromMap(map);
  }

  /// 💾 保存宗门
  static Future<void> saveZongmen(Zongmen zongmen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zongmenKey, json.encode(zongmen.toMap()));
  }

  /// 📤 加载弟子 + 更新年龄
  static Future<List<Disciple>> loadDisciples() async {
    final box = await Hive.openBox<Disciple>('disciples');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeRate = 10000;

    final List<Disciple> zongmenDisciples = [];

    for (final d in box.values) {
      if (d.joinedAt == null) continue;

      final passed = (now - d.joinedAt!) * timeRate;
      final years = (passed / (3600 * 24 * 365)).floor();

      if (years > d.age) {
        final newD = d.copyWith(age: years);
        await box.put(newD.id, newD);
        zongmenDisciples.add(newD);
      } else {
        zongmenDisciples.add(d);
      }
    }

    return zongmenDisciples;
  }

  static Future<void> addDisciple(Disciple d) async {
    final box = await Hive.openBox<Disciple>('disciples');
    if (!box.containsKey(d.id)) {
      await box.put(d.id, d);
    }
  }

  static Future<void> saveDisciple(Disciple d) async {
    final box = await Hive.openBox<Disciple>('disciples');
    await box.put(d.id, d);
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

  static Future<void> clearDiscipleRoom(String discipleId) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final d = box.get(discipleId);
    if (d != null && d.assignedRoom != null) {
      await box.put(d.id, d.copyWith(assignedRoom: null));
    }
  }

  static Future<void> clearRoomAssignments(String room) async {
    final box = await Hive.openBox<Disciple>('disciples');
    for (final d in box.values) {
      if (d.assignedRoom == room) {
        await box.put(d.id, d.copyWith(assignedRoom: null));
      }
    }
  }

  /// 🪙 计算升级所需下品灵石
  static BigInt requiredStones(int level) {
    const base = 100000;
    return BigInt.from(base) * BigInt.from(10).pow(level - 1);
  }

  /// 🪙 升级宗门（消耗下品灵石）
  static Future<Zongmen> upgradeSectLevel(Zongmen zongmen) async {
    final currentLevel = zongmen.sectLevel;
    final required = requiredStones(currentLevel);

    // 查询灵石
    final stones = await ResourcesStorage.getValue('spiritStoneLow');
    if (stones < required) {
      throw Exception('下品灵石不足，需要：$required');
    }

    // 扣除
    await ResourcesStorage.subtract('spiritStoneLow', required);

    // 升级
    final newZongmen = zongmen.copyWith(sectLevel: currentLevel + 1);
    await saveZongmen(newZongmen);

    return newZongmen;
  }

  /// 🧍 保存职位（职位是弟子 ID 与房间的映射）
  static Future<void> setDiscipleRole(String discipleId, String role) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final zongmen = await loadZongmen();
    final sectLevel = zongmen?.sectLevel ?? 1;

    final roleMax = SectRoleLimits.getMax(role, sectLevel);
    final disciples = box.values.toList();

    final others = disciples.where((d) => d.role == role && d.id != discipleId).toList();

    if (role != '弟子' && others.length >= roleMax) {
      others.sort((a, b) => (a.joinedAt ?? 0).compareTo(b.joinedAt ?? 0));
      final kicked = others.first;
      await box.put(kicked.id, kicked.copyWith(role: '弟子'));
    }

    final d = box.get(discipleId);
    if (d != null) {
      await box.put(d.id, d.copyWith(role: role));
    }
  }

  static Future<Map<String, Disciple>> getAssignedRoles() async {
    final box = await Hive.openBox<Disciple>('disciples');
    return {
      for (final d in box.values)
        if (d.role != '弟子') d.role!: d
    };
  }

  static Future<void> clearRole(String role) async {
    final box = await Hive.openBox<Disciple>('disciples');
    for (final d in box.values) {
      if (d.role == role) {
        await box.put(d.id, d.copyWith(role: '弟子'));
      }
    }
  }

  /// 🧮 根据宗门等级计算最大弟子数量
  static int calcMaxDiscipleCount(int sectLevel) {
    return 5 * sectLevel;
  }
}
