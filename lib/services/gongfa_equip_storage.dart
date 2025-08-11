// 📄 lib/services/gongfa_equip_storage.dart
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';

/// 功法装备存储（按 type 分槽）
/// 当前实现：movement 槽（速度功法）
/// 存储形态：Player.techniques = { type: [ids] }
class GongfaEquipStorage {
  static const String _movementKey = 'movement';

  /// 读取玩家当前装备的【速度功法】（没有则返回 null）
  static Future<Gongfa?> loadEquippedMovementBy(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return null;

    // 取 map（兼容：若为空，尝试从对象列表聚合一份）
    final techMap = _ensureTechMap(p);

    final ids = techMap[_movementKey] ?? const <String>[];
    if (ids.isEmpty) return null;

    final all = await GongfaCollectedStorage.getAllGongfa();
    for (final id in ids) {
      final g = all.firstWhere(
            (x) => x.id == id && x.type == GongfaType.movement,
        orElse: () => null as Gongfa,
      );
      try {
        if (g != null) return g;
      } catch (_) {}
    }
    return null;
  }

  /// 装备一本【速度功法】（同槽互斥）
  static Future<void> equipMovement({
    required String ownerId,
    required Gongfa gongfa,
  }) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _ensureTechMap(p);

    // 同槽互斥：movement 只保留当前这一本
    techMap[_movementKey] = <String>[gongfa.id];

    await PlayerStorage.updateFields({
      'techniques': techMap,              // {type: [ids]}
      'moveSpeedBoost': gongfa.moveSpeedBoost, // 0~1 小数
    });

    // 标记已学（如需持久化到仓库可加 update 方法）
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

  /// 兜底：根据 movement 槽重算 moveSpeedBoost
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
    Gongfa? cur;
    for (final id in ids) {
      final g = all.firstWhere(
            (x) => x.id == id && x.type == GongfaType.movement,
        orElse: () => null as Gongfa,
      );
      try {
        if (g != null) { cur = g; break; }
      } catch (_) {}
    }

    await PlayerStorage.updateFields({
      'moveSpeedBoost': cur?.moveSpeedBoost ?? 0.0,
    });
  }

  // =======================
  // 工具：拿到 {type: [ids]}，并兼容旧数据
  // =======================

  static Map<String, List<String>> _ensureTechMap(dynamic player) {
    // 先用已解析的 map
    if (player.techniquesMap is Map<String, List<String>> &&
        (player.techniquesMap as Map<String, List<String>>).isNotEmpty) {
      return Map<String, List<String>>.from(player.techniquesMap);
    }

    // 其次用对象列表聚合
    if (player.techniques is List<Gongfa> && (player.techniques as List<Gongfa>).isNotEmpty) {
      final map = <String, List<String>>{};
      for (final g in player.techniques as List<Gongfa>) {
        final k = g.type.name;
        (map[k] ??= <String>[]).add(g.id);
      }
      return map.map((k, v) => MapEntry(k, v.toSet().toList()));
    }

    // 最后兜底：如果底层存的还是 List<String>（历史格式），按 movement 塞进去
    try {
      final raw = player.toJson()['techniques'];
      if (raw is List) {
        final ids = raw.whereType<String>().toList();
        if (ids.isNotEmpty) return {_movementKey: ids};
      } else if (raw is Map) {
        // 已经是 map 的话直接转
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
