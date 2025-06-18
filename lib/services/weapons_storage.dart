import 'package:hive/hive.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_blueprint_service.dart';
import '../models/refine_blueprint.dart';
import '../models/weapon.dart';

class WeaponsStorage {
  static const String _boxName = 'weapons_box';

  // 🔐 打开盒子（私有）
  static Future<Box<Weapon>> _openBox() async {
    return await Hive.openBox<Weapon>(_boxName);
  }

  // ✅ 添加新武器
  static Future<void> addWeapon(Weapon weapon) async {
    final box = await _openBox();
    await box.add(weapon);
  }

  /// ✅ 根据蓝图创建新武器
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

  // ✅ 获取所有武器
  static Future<List<Weapon>> loadAllWeapons() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // ✅ 获取带 Hive key 的所有武器
  static Future<Map<dynamic, Weapon>> loadWeaponsWithKeys() async {
    final box = await _openBox();
    return box.toMap();
  }

  // ✅ 删除某个武器
  static Future<void> deleteWeaponByKey(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  // ✅ 清空所有武器
  static Future<void> clearAllWeapons() async {
    final box = await _openBox();
    await box.clear();
  }

  // ✅ 按创建时间排序
  static Future<List<Weapon>> loadSortedByTimeDesc() async {
    final list = await loadAllWeapons();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ✅ 设置武器装备给某人
  static Future<void> equipWeapon(Weapon weapon, String targetId) async {
    final box = await _openBox();
    final key = weapon.key;
    if (key != null) {
      weapon.equippedById = targetId;
      await weapon.save();
    }
  }

  // ✅ 解除武器装备
  static Future<void> unequipWeapon(Weapon weapon) async {
    final box = await _openBox();
    final key = weapon.key;
    if (key != null) {
      weapon.equippedById = null;
      await weapon.save();
    }
  }

  // ✅ 根据持有者ID查找装备的武器
  static Future<List<Weapon>> loadWeaponsEquippedBy(String ownerId) async {
    final box = await _openBox();
    return box.values.where((w) => w.equippedById == ownerId).toList();
  }

  // ✅ 获取未被装备的所有武器
  static Future<List<Weapon>> loadUnEquippedWeapons() async {
    final box = await _openBox();
    return box.values.where((w) => w.equippedById == null).toList();
  }
}

