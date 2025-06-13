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
    print('📥 [saveZongmen] 准备存储 Zongmen 数据：');
    for (final d in zongmen.disciples) {
      print('   - ${d.name} => assignedRoom: ${d.assignedRoom}');
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(zongmen.toMap());
    await prefs.setString(_zongmenKey, jsonStr);

    // ✅ 立刻读取验证
    final raw = prefs.getString(_zongmenKey);
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      final verifyZongmen = Zongmen.fromMap(map);
      print('🔁 [saveZongmen] 验证读取结果：');
      for (final d in verifyZongmen.disciples) {
        print('   - ${d.name} => assignedRoom: ${d.assignedRoom}');
      }
    } else {
      print('❌ [saveZongmen] 存完立刻读取，结果是 null！');
    }
  }
  /// 弟子列表读取 & 年龄更新同上
  static Future<List<Disciple>> loadDisciples() async {
    final z = await loadZongmen();
    if (z == null) return [];

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const timeRate = 10000;

    final List<Disciple> original = z.disciples;
    final List<Disciple> updated = [];

    bool hasChange = false;

    for (final d in original) {
      if (d.joinedAt == null) {
        updated.add(d);
        continue;
      }

      final passed = (now - d.joinedAt!) * timeRate;
      final years = (passed / (3600 * 24 * 365)).floor();

      if (years > d.age) {
        final newD = d.copyWith(age: years);
        updated.add(newD);
        hasChange = true;
      } else {
        updated.add(d);
      }
    }

    // ✅ 只有发生变化才保存
    if (hasChange) {
      print('📝 [loadDisciples] 年龄有变更，执行保存');
      await saveDisciples(updated);
    } else {
      print('✅ [loadDisciples] 所有年龄已是最新，无需保存');
    }

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

  ///  设置弟子驻守房间
  static Future<void> setDiscipleAssignedRoom(String discipleId, String room) async {
    final z = await loadZongmen();
    if (z == null) return;

    final List<Disciple> updated = [];

    for (final d in z.disciples) {
      if (d.id == discipleId) {
        print('📌 设置 ${d.name} 为房间 [$room]');
        updated.add(d.copyWith(assignedRoom: room));
      } else if (d.assignedRoom == room) {
        print('🚫 清除 ${d.name} 原本驻守在 [$room]');
        updated.add(d.copyWith(assignedRoom: null));
      } else {
        updated.add(d);
      }
    }

    final newZongmen = z.copyWith(disciples: updated);
    await saveZongmen(newZongmen);

    print('📥 [saveZongmen] 准备存储 Zongmen 数据：');
    for (final d in newZongmen.disciples) {
      print('   - ${d.name} => assignedRoom: ${d.assignedRoom}');
    }

    final reloaded = await loadZongmen();
    print('🔁 [验证读取结果]：');
    for (final d in reloaded!.disciples) {
      print('   - ${d.name} => assignedRoom: ${d.assignedRoom}');
    }
  }

  static Future<void> removeDiscipleFromRoom(String discipleId, String room) async {
    final z = await loadZongmen();
    if (z == null) return;

    final updated = z.disciples.map((d) {
      if (d.id == discipleId && d.assignedRoom == room) {
        print('❌ 移除 ${d.name} 从房间 [$room]');
        return d.copyWith(assignedRoom: null);
      }
      return d;
    }).toList();

    final newZongmen = z.copyWith(disciples: updated);
    await saveZongmen(newZongmen);

    print('📤 [removeDiscipleFromRoom] 当前房间数据：');
    for (final d in newZongmen.disciples) {
      print('   - ${d.name} => assignedRoom: ${d.assignedRoom}');
    }
  }

  /// 获取当前驻守在某房间的弟子
  static Future<List<Disciple>> getDisciplesByRoom(String room) async {
    final list = await loadDisciples();
    final result = list.where((d) => d.assignedRoom == room).toList();
    print('📦 当前房间 [$room] 驻守弟子列表: ${result.map((d) => d.name).toList()}');
    return result;
  }

  /// 获取某房间的第一个驻守者（适用于单人房）
  static Future<void> clearRoomAssignments(String room) async {
    final list = await loadDisciples();
    final updated = list.map((d) {
      if (d.assignedRoom == room) {
        print('❌ 清除弟子 ${d.name} 在房间 [$room] 的驻守');
        return d.copyWith(assignedRoom: null);
      }
      return d;
    }).toList();
    await saveDisciples(updated);
  }

}
