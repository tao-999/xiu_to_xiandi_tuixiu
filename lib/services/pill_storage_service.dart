import 'package:hive/hive.dart';
import '../models/disciple.dart';
import '../models/pill.dart';
import 'player_storage.dart';

class PillStorageService {
  static const String _boxName = 'pills';

  static Future<Box<Pill>> _openBox() async {
    return await Hive.openBox<Pill>(_boxName);
  }

  static Future<void> addPill(Pill pill) async {
    final box = await _openBox();
    final same = box.values.where((p) =>
    p.name == pill.name &&
        p.level == pill.level &&
        p.type == pill.type &&
        p.bonusAmount == pill.bonusAmount,
    ).cast<Pill>().toList().firstOrNull;

    if (same != null) {
      same.count += pill.count;
      await same.save();
    } else {
      await box.add(pill);
    }
  }

  static Future<void> deletePillByKey(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  static Future<List<Pill>> loadAllPills() async {
    final box = await _openBox();
    return box.values.toList();
  }

  static Future<Map<dynamic, Pill>> loadPillsWithKeys() async {
    final box = await _openBox();
    return box.toMap();
  }

  static Future<List<Pill>> loadSortedByTimeDesc() async {
    final list = await loadAllPills();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> clearAllPills() async {
    final box = await _openBox();
    await box.clear();
  }

  /// ✅ 吞服丹药：减少数量并更新角色属性
  static Future<void> consumePill(Pill pill, {int count = 1}) async {
    final box = await _openBox();
    final key = pill.key;
    final stored = box.get(key);

    // 🔥 计算总加成
    final totalBonus = pill.bonusAmount * count;

    // 🧙‍♂️ 更新角色属性（base）
    final player = await PlayerStorage.getPlayer();
    if (player != null) {
      switch (pill.type.name) {
        case 'health':
          player.baseHp += totalBonus;
          await PlayerStorage.updateField('baseHp', player.baseHp);
          break;
        case 'attack':
          player.baseAtk += totalBonus;
          await PlayerStorage.updateField('baseAtk', player.baseAtk);
          break;
        case 'defense':
          player.baseDef += totalBonus;
          await PlayerStorage.updateField('baseDef', player.baseDef);
          break;
        default:
          break;
      }
    }

    // 🧪 扣减数量
    if (stored != null) {
      stored.count -= count;
      if (stored.count <= 0) {
        await stored.delete();
      } else {
        await stored.save();
      }
    }
  }

  static Future<void> consumePillForDisciple(Disciple disciple, Pill pill, {int count = 1}) async {
    final box = await _openBox();
    final key = pill.key;
    final stored = box.get(key);

    final totalBonus = pill.bonusAmount * count;

    // ✅ 直接叠加到 base 属性
    switch (pill.type.name) {
      case 'health':
        disciple.hp += totalBonus;
        break;
      case 'attack':
        disciple.atk += totalBonus;
        break;
      case 'defense':
        disciple.def += totalBonus;
        break;
    }

    await disciple.save(); // ✅ Hive commit

    // 🧪 扣减丹药数量
    if (stored != null) {
      stored.count -= count;
      if (stored.count <= 0) {
        await stored.delete();
      } else {
        await stored.save();
      }
    }
  }
}
