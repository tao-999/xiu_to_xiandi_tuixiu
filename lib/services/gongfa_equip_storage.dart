// 📄 lib/services/gongfa_equip_storage.dart
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';

/// 功法装备存储（按 type 分槽）
/// 当前实现：movement 槽（速度功法）
/// 存储形态：Player.techniques = { type: [ids] }
class GongfaEquipStorage {
  static const String _movementKey = 'movement';

  /// 读取玩家当前装备的【速度功法】（没有或已失效则返回 null，且自动自愈卸下）
  static Future<Gongfa?> loadEquippedMovementBy(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return null;

    final techMap = _ensureTechMap(p);
    final ids = techMap[_movementKey] ?? const <String>[];
    if (ids.isEmpty) return null;

    // 背包里按 id 找“同 id 的最高等级”那本
    final all = await GongfaCollectedStorage.getAllGongfa();
    Gongfa? pickById(String id) {
      Gongfa? best;
      for (final g in all) {
        if (g.id == id && g.type == GongfaType.movement) {
          if (best == null || g.level > best.level) best = g;
        }
      }
      return best;
    }

    // 按槽位记录顺序选第一本“背包仍存在”的
    for (final id in ids) {
      final g = pickById(id);
      if (g != null) return g;
    }

    // 槽位里没有任何有效 id → 自愈卸下
    techMap.remove(_movementKey);
    await PlayerStorage.updateFields({
      'techniques': techMap,
      'moveSpeedBoost': 0.0,
    });
    return null;
  }

  /// 装备一本【速度功法】（同槽互斥，仅保留当前这一本 id）
  static Future<void> equipMovement({
    required String ownerId,
    required Gongfa gongfa,
  }) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _ensureTechMap(p);
    techMap[_movementKey] = <String>[gongfa.id];

    await PlayerStorage.updateFields({
      'techniques': techMap,                     // {type: [ids]}
      'moveSpeedBoost': gongfa.moveSpeedBoost,   // 同步数值
    });

    // 标记已学（如需持久化到仓库请在相应仓库更新）
    gongfa.isLearned = true;
  }

  /// 卸下【速度功法】
  static Future<void> unequipMovement(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _ensureTechMap(p);
    techMap.remove(_movementKey);

    await PlayerStorage.updateFields({
      'techniques': techMap,
      'moveSpeedBoost': 0.0,
    });
  }

  /// 兜底：根据 movement 槽重算 moveSpeedBoost（槽位失效则自动卸下归零）
  static Future<void> resyncMovement(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _ensureTechMap(p);
    final ids = techMap[_movementKey] ?? const <String>[];

    if (ids.isEmpty) {
      await PlayerStorage.updateFields({'moveSpeedBoost': 0.0});
      return;
    }

    final all = await GongfaCollectedStorage.getAllGongfa();

    Gongfa? pickById(String id) {
      Gongfa? best;
      for (final g in all) {
        if (g.id == id && g.type == GongfaType.movement) {
          if (best == null || g.level > best.level) best = g;
        }
      }
      return best;
    }

    Gongfa? cur;
    for (final id in ids) {
      final g = pickById(id);
      if (g != null) { cur = g; break; }
    }

    if (cur == null) {
      // 槽位全失效 → 自愈卸下并归零
      techMap.remove(_movementKey);
      await PlayerStorage.updateFields({
        'techniques': techMap,
        'moveSpeedBoost': 0.0,
      });
    } else {
      await PlayerStorage.updateFields({
        'moveSpeedBoost': cur.moveSpeedBoost,
      });
    }
  }

  // =======================
  // 工具：拿到 {type: [ids]}，并兼容旧数据
  // =======================
  static Map<String, List<String>> _ensureTechMap(dynamic player) {
    // 1) 已解析 map
    if (player.techniquesMap is Map) {
      final raw = Map<String, dynamic>.from(player.techniquesMap as Map);
      final out = <String, List<String>>{};
      raw.forEach((k, v) {
        if (v is List) out[k] = v.whereType<String>().toList();
      });
      return out;
    }

    // 2) 旧格式：对象列表
    if (player.techniques is List<Gongfa> && (player.techniques as List<Gongfa>).isNotEmpty) {
      final map = <String, List<String>>{};
      for (final g in player.techniques as List<Gongfa>) {
        final k = g.type.name;
        (map[k] ??= <String>[]).add(g.id);
      }
      // 去重
      return map.map((k, v) => MapEntry(k, v.toSet().toList()));
    }

    // 3) 最老格式：List<String> 或 Map 混存在 toJson 里
    try {
      final raw = player.toJson()['techniques'];
      if (raw is List) {
        final ids = raw.whereType<String>().toList();
        if (ids.isNotEmpty) return {_movementKey: ids};
      } else if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final out = <String, List<String>>{};
        m.forEach((k, v) {
          if (v is List) out[k] = v.whereType<String>().toList();
        });
        return out;
      }
    } catch (_) {}

    return <String, List<String>>{};
  }
}
