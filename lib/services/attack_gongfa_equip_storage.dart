// 📄 lib/services/attack_gongfa_equip_storage.dart
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';

/// 攻击功法装备存储（只操作 Player.techniquesMap = { type: [ids] }）
/// 槽位：'attack'；不改任何数值属性
class AttackGongfaEquipStorage {
  static const String _attackKey = 'attack';

  /// 读取玩家当前装备的【攻击功法】（没有则返回 null）
  static Future<Gongfa?> loadEquippedAttackBy(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return null;

    final Map<String, List<String>> techMap =
        (p.techniquesMap as Map<String, List<String>>?) ?? <String, List<String>>{};

    final ids = techMap[_attackKey];
    if (ids == null || ids.isEmpty) return null;

    final all = await GongfaCollectedStorage.getAllGongfa();
    for (final id in ids) {
      for (final g in all) {
        if (g.id == id && g.type == GongfaType.attack) return g;
      }
    }
    return null;
  }

  /// 装备一本【攻击功法】（同槽互斥，仅写 techniquesMap）
  static Future<void> equipAttack({
    required String ownerId,
    required Gongfa gongfa,
  }) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final Map<String, List<String>> techMap =
        (p.techniquesMap as Map<String, List<String>>?) ?? <String, List<String>>{};

    // 同槽互斥：只保留当前这一本
    techMap[_attackKey] = <String>[gongfa.id];

    await PlayerStorage.updateFields({
      'techniquesMap': Map<String, List<String>>.from(techMap),
    });
  }

  /// 卸下【攻击功法】（仅写 techniquesMap）
  static Future<void> unequipAttack(String ownerId) async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;

    final Map<String, List<String>> techMap =
        (p.techniquesMap as Map<String, List<String>>?) ?? <String, List<String>>{};

    techMap.remove(_attackKey);

    await PlayerStorage.updateFields({
      'techniquesMap': Map<String, List<String>>.from(techMap),
    });
  }
}
