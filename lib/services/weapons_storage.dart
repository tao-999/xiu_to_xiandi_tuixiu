import 'package:hive/hive.dart';
import 'package:xiu_to_xiandi_tuixiu/models/weapon.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import '../models/refine_blueprint.dart';

class WeaponsStorage {
  static const String _boxName = 'weapons';

  static Future<Box<Weapon>> _openBox() async {
    return await Hive.openBox<Weapon>(_boxName);
  }

  static Future<void> addWeapon(Weapon weapon) async {
    final box = await _openBox();
    await box.add(weapon);
  }

  static Future<void> createFromBlueprint(RefineBlueprint blueprint, {DateTime? createdAt}) async {
    final effect = RefineBlueprintService.getEffectMeta(blueprint);

    final weapon = Weapon(
      name: blueprint.name,
      level: blueprint.level,
      type: blueprint.type.name,
      createdAt: createdAt ?? DateTime.now(),
      attackBoost: blueprint.attackBoost,
      defenseBoost: blueprint.defenseBoost,
      hpBoost: blueprint.healthBoost,
      specialEffects: ['${effect['type']} +${effect['value']}'],
      iconPath: 'assets/images/${blueprint.iconPath}',
    );

    await addWeapon(weapon);
  }

  static Future<List<Weapon>> loadAllWeapons() async {
    final box = await _openBox();
    return box.values.toList();
  }

  static Future<Map<dynamic, Weapon>> loadWeaponsWithKeys() async {
    final box = await _openBox();
    return box.toMap();
  }

  static Future<void> deleteWeaponByKey(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  static Future<void> clearAllWeapons() async {
    final box = await _openBox();
    await box.clear();
  }

  static Future<List<Weapon>> loadSortedByTimeDesc() async {
    final list = await loadAllWeapons();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> equipWeapon({
    required Weapon weapon,
    required String ownerId,
  }) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    // ✅ 先清除 owner 旧装备（同类型）
    final box = await _openBox();
    final equipped = box.values.where((w) => w.equippedById == ownerId && w.type == weapon.type);

    for (final old in equipped) {
      await _removeWeaponBonusFromPlayer(player, old);
      old.equippedById = null;
      await old.save();
    }

    // ✅ 装备新武器
    weapon.equippedById = ownerId;
    await weapon.save();

    // ✅ 加成新装备属性
    await _addWeaponBonusToPlayer(player, weapon);
  }

  static Future<void> unequipWeapon(Weapon weapon) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    await _removeWeaponBonusFromPlayer(player, weapon);

    weapon.equippedById = null;
    await weapon.save();
  }

  static Future<void> unequipWeaponsByOwner(String ownerId) async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final box = await _openBox();
    final ownedWeapons = box.values.where((w) => w.equippedById == ownerId);

    for (final weapon in ownedWeapons) {
      await _removeWeaponBonusFromPlayer(player, weapon);
      weapon.equippedById = null;
      await weapon.save();
    }
  }

  static Future<List<Weapon>> loadWeaponsEquippedBy(String ownerId) async {
    final box = await _openBox();
    return box.values.where((w) => w.equippedById == ownerId).toList();
  }

  static Future<List<Weapon>> loadUnEquippedWeapons() async {
    final box = await _openBox();
    return box.values.where((w) => w.equippedById == null).toList();
  }

  // 🌟 属性增减方法
  static Future<void> _addWeaponBonusToPlayer(Character player, Weapon weapon) async {
    player.extraHp += weapon.hpBoost / 100.0;
    player.extraAtk += weapon.attackBoost / 100.0;
    player.extraDef += weapon.defenseBoost / 100.0;

    await PlayerStorage.updateFields({
      'extraHp': player.extraHp,
      'extraAtk': player.extraAtk,
      'extraDef': player.extraDef,
    });
  }

  static Future<void> _removeWeaponBonusFromPlayer(Character player, Weapon weapon) async {
    player.extraHp -= weapon.hpBoost / 100.0;
    player.extraAtk -= weapon.attackBoost / 100.0;
    player.extraDef -= weapon.defenseBoost / 100.0;

    await PlayerStorage.updateFields({
      'extraHp': player.extraHp,
      'extraAtk': player.extraAtk,
      'extraDef': player.extraDef,
    });
  }
}
