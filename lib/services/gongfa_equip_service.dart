import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

/// 通用功法装备服务：统一读写 Player.techniquesMap = { slot: [gongfaId] }
/// 只保留“当前格式”，不做历史兼容。
class GongfaEquipService {
  // 约定的槽位 key（你也可以扩展更多，比如 'defense'、'aura'）
  static const String movementSlot = 'movement';
  static const String attackSlot   = 'attack';

  /// 读取指定槽已装备的功法（按类型校验；未装备返回 null）
  static Future<Gongfa?> loadEquipped({
    required String slot,
    required GongfaType type,
  }) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return null;

    final techMap = _readTechMap(p);
    final ids = techMap[slot] ?? const <String>[];
    if (ids.isEmpty) return null;

    final all = await GongfaCollectedStorage.getAllGongfa();
    for (final id in ids) {
      for (final g in all) {
        if (g.id == id && g.type == type) return g;
      }
    }
    return null;
  }

  /// 装备一本功法（同槽互斥）。必要时做槽位副作用（如 movement 同步 moveSpeedBoost）。
  static Future<void> equip({
    required String slot,
    required Gongfa gongfa,
  }) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _readTechMap(p);
    techMap[slot] = <String>[gongfa.id];

    final update = <String, dynamic>{'techniquesMap': techMap};

    // 槽位副作用：速度槽同步移速加成；其他槽不改数值
    if (slot == movementSlot) {
      update['moveSpeedBoost'] = gongfa.moveSpeedBoost; // 0~1
    }

    await PlayerStorage.updateFields(update);
  }

  /// 卸下槽位
  static Future<void> unequip(String slot) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final techMap = _readTechMap(p);
    techMap.remove(slot);

    final update = <String, dynamic>{'techniquesMap': techMap};
    if (slot == movementSlot) {
      update['moveSpeedBoost'] = 0.0;
    }
    await PlayerStorage.updateFields(update);
  }

  ///（可选）进入游戏时重算一次速度槽的 moveSpeedBoost
  static Future<void> resyncMovementBoost() async {
    final g = await loadEquipped(slot: movementSlot, type: GongfaType.movement);
    await PlayerStorage.updateFields({'moveSpeedBoost': g?.moveSpeedBoost ?? 0.0});
  }

  // ------- internal -------
  static Map<String, List<String>> _readTechMap(dynamic player) {
    final raw = player.techniquesMap;
    if (raw is Map) {
      final out = <String, List<String>>{};
      raw.forEach((k, v) {
        if (v is List) out[k] = v.whereType<String>().toList();
      });
      return out;
    }
    return <String, List<String>>{};
  }
}
