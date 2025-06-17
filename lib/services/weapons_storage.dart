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

  /// ✅ 直接通过蓝图构建并保存武器（统一发放）
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
      specialEffects: [
        '${effect['type']} +${effect['value']}',
      ],
    );

    await addWeapon(weapon);
  }

  // ✅ 获取所有武器
  static Future<List<Weapon>> loadAllWeapons() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // ✅ 删除某个武器（通过 Hive 的 key）
  static Future<void> deleteWeaponByKey(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  // ✅ 清空所有武器（慎用）
  static Future<void> clearAllWeapons() async {
    final box = await _openBox();
    await box.clear();
  }

  // ✅ 获取带 Hive key 的所有武器（用于 UI 渲染）
  static Future<Map<dynamic, Weapon>> loadWeaponsWithKeys() async {
    final box = await _openBox();
    return box.toMap();
  }

  // ✅ 按创建时间倒序排列（最新的排前面）
  static Future<List<Weapon>> loadSortedByTimeDesc() async {
    final list = await loadAllWeapons();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
