import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/zongmen.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

import '../utils/sect_role_limits.dart';

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
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeRate = 10000;

    final List<Disciple> zongmenDisciples = [];

    for (final d in box.values) {
      if (d.joinedAt == null) continue; // 🚫 未加入宗门，跳过

      // ✅ 放在这，保证是宗门弟子才打印
      print('🧬 加载宗门弟子：${d.name}（id=${d.id}）→ assignedRoom=${d.assignedRoom}');

      final passed = (now - d.joinedAt!) * timeRate;
      final years = (passed / (3600 * 24 * 365)).floor();

      if (years > d.age) {
        final newD = d.copyWith(age: years);

        print("🔥 年龄更新！${newD.name} → assignedRoom=${newD.assignedRoom}"); // 👈 看这里是不是 null 了

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

  /// 🧍 保存职位（职位是弟子 ID 与房间的映射）
  /// 如果要设为无职位，传 null 即可
  /// 🧍 设置弟子职位（含“弟子”），并保证职位唯一（除“弟子”外）
  static Future<void> setDiscipleRole(String discipleId, String role) async {
    final box = await Hive.openBox<Disciple>('disciples');
    final zongmen = await loadZongmen();
    final sectExp = zongmen?.sectExp ?? 0;
    final sectLevel = calcSectLevel(sectExp);

    final roleMax = SectRoleLimits.getMax(role, sectLevel);
    final disciples = box.values.toList();

    // ✅ 找出当前拥有该角色的人（除了自己）
    final others = disciples
        .where((d) => d.role == role && d.id != discipleId)
        .toList();

    if (role != '弟子' && others.length >= roleMax) {
      // 🔥 如果已满，踢掉一个（比如最早加入的那个）
      others.sort((a, b) => (a.joinedAt ?? 0).compareTo(b.joinedAt ?? 0));
      final kicked = others.first;
      await box.put(kicked.id, kicked.copyWith(role: '弟子'));
    }

    // ✅ 设置新角色
    final d = box.get(discipleId);
    if (d != null) {
      await box.put(d.id, d.copyWith(role: role));
    }
  }

  /// 获取当前宗门的所有职位分配情况（map：职位 => 弟子）
  /// 📋 获取所有非“弟子”的职位对应弟子（比如宗主、长老、执事）
  static Future<Map<String, Disciple>> getAssignedRoles() async {
    final box = await Hive.openBox<Disciple>('disciples');
    return {
      for (final d in box.values)
        if (d.role != '弟子') d.role!: d
    };
  }

  /// 🧹 把某职位的弟子踢下岗 → 改为“弟子”
  static Future<void> clearRole(String role) async {
    final box = await Hive.openBox<Disciple>('disciples');
    for (final d in box.values) {
      if (d.role == role) {
        await box.put(d.id, d.copyWith(role: '弟子'));
      }
    }
  }

}
