import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import '../models/disciple.dart';
import '../utils/cultivation_level.dart';
import '../widgets/constants/aptitude_table.dart';

class ZongmenDiscipleService {
  /// 🌟 同步所有弟子的境界到玩家当前境界
  static Future<void> syncAllRealmWithPlayer() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final level = calculateCultivationLevel(player.cultivation);
    final realmName = "${level.realm}${level.rank}重";

    debugPrint('🌟 同步弟子境界：玩家=$realmName');

    final disciples = await ZongmenStorage.loadDisciples();

    for (var d in disciples) {
      final realmLayer = _parseRealmLayer(realmName);

      final attr = calculateAttributesForRealm(
        aptitude: d.aptitude,
        realmLayer: realmLayer,
      );

      final updated = d.copyWith(
        realm: realmName,
        hp: attr['hp'],
        atk: attr['atk'],
        def: attr['def'],
      );

      await ZongmenStorage.saveDisciple(updated);

      debugPrint('✅ ${d.name} → 同步到境界=$realmName, HP=${attr['hp']}, ATK=${attr['atk']}, DEF=${attr['def']}');
    }
  }

  /// ✨ 统一计算宗门弟子的战力
  static int calculatePower(Disciple d) {
    return (d.hp * 0.4 + d.atk * 2 + d.def * 1.5).toInt();
  }

  /// 🧮 创建弟子的初始属性
  static Map<String, int> calculateInitialAttributes(int aptitude) {
    return {
      'hp': 100 + (aptitude - 31),
      'atk': 20 + (aptitude - 31),
      'def': 10 + (aptitude - 31),
    };
  }

  /// 🧗‍♂️ 根据境界阶数和资质，计算当前属性
  static Map<String, int> calculateAttributesForRealm({
    required int aptitude,
    required int realmLayer,
  }) {
    final base = calculateInitialAttributes(aptitude);
    final layerCount = (realmLayer - 1).clamp(0, 9999);

    final hpPerLayer = (aptitude * 5) + (realmLayer * 10);
    final atkPerLayer = (aptitude * 1.2).toInt() + (realmLayer * 2);
    final defPerLayer = (aptitude * 0.8).toInt() + (realmLayer);

    return {
      'hp': base['hp']! + hpPerLayer * layerCount,
      'atk': base['atk']! + atkPerLayer * layerCount,
      'def': base['def']! + defPerLayer * layerCount,
    };
  }

  /// 🧮 将 "筑基3重" 转换为层数
  static int _parseRealmLayer(String realmName) {
    for (int i = 0; i < aptitudeTable.length; i++) {
      final gate = aptitudeTable[i];
      if (realmName.startsWith(gate.realmName)) {
        final reg = RegExp(r'\d+');
        final match = reg.firstMatch(realmName);
        final rank = match != null ? int.parse(match.group(0)!) : 1;
        return (i * 10) + rank;
      }
    }
    // fallback: 炼气1层
    return 1;
  }

  static const _sortOptionKey = 'zongmen_disciple_sort_option';

  /// 📋 保存宗门弟子排序选项
  static Future<void> saveSortOption(String option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOptionKey, option);
  }

  /// 📋 加载宗门弟子排序选项
  static Future<String> loadSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOptionKey) ?? 'apt_desc';
  }

}
