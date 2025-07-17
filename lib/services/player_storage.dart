import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';
import '../utils/cultivation_level.dart';
import '../utils/lingshi_util.dart';
import 'cultivation_tracker.dart';

class PlayerStorage {
  static const _playerKey = 'playerData';

  static Future<void> updateField(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json[key] = value;
    await prefs.setString(_playerKey, jsonEncode(json));
  }

  static Future<void> updateFields(Map<String, dynamic> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json.addAll(fields);
    await prefs.setString(_playerKey, jsonEncode(json));
  }

  static Future<Character?> getPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey);
    if (raw == null) return null;
    return Character.fromJson(jsonDecode(raw));
  }

  static int calculatePower({required int hp, required int atk, required int def}) {
    return (hp * 0.4 + atk * 2 + def * 1.5).toInt();
  }

  static Future<int> getCultivationLayer() async {
    final player = await getPlayer();
    if (player == null) return 1;
    return calculateCultivationLevel(player.cultivation).totalLayer;
  }

  static Future<double> getSizeMultiplier() async {
    final layer = await getCultivationLayer();
    return 1.0 + (layer - 1) * 0.005;
  }

  static Future<void> addCultivationByStones({
    BigInt? low,
    BigInt? mid,
    BigInt? high,
    BigInt? supreme,
    void Function()? onUpdate,
  }) async {
    final l = low ?? BigInt.zero;
    final m = mid ?? BigInt.zero;
    final h = high ?? BigInt.zero;
    final s = supreme ?? BigInt.zero;

    final resLow = await ResourcesStorage.getValue('spiritStoneLow');
    final resMid = await ResourcesStorage.getValue('spiritStoneMid');
    final resHigh = await ResourcesStorage.getValue('spiritStoneHigh');
    final resSupreme = await ResourcesStorage.getValue('spiritStoneSupreme');

    if (resLow < l || resMid < m || resHigh < h || resSupreme < s) {
      debugPrint('灵石不足');
      onUpdate?.call();
      return;
    }

    await ResourcesStorage.subtract('spiritStoneLow', l);
    await ResourcesStorage.subtract('spiritStoneMid', m);
    await ResourcesStorage.subtract('spiritStoneHigh', h);
    await ResourcesStorage.subtract('spiritStoneSupreme', s);

    final addedExp = calculateAddedExp(low: l, mid: m, high: h, supreme: s);
    final player = await getPlayer();
    if (player == null) {
      onUpdate?.call();
      return;
    }

    final beforeLayer = calculateCultivationLevel(player.cultivation).totalLayer;
    await CultivationTracker.safeAddExp(addedExp);
    await applyBreakthroughIfNeeded(player, beforeLayer);
    onUpdate?.call();
  }

  static BigInt calculateAddedExp({
    BigInt? low,
    BigInt? mid,
    BigInt? high,
    BigInt? supreme,
  }) {
    final l = low ?? BigInt.zero;
    final m = mid ?? BigInt.zero;
    final h = high ?? BigInt.zero;
    final s = supreme ?? BigInt.zero;

    return (l * lingShiRates[LingShiType.lower]! +
        m * lingShiRates[LingShiType.middle]! +
        h * lingShiRates[LingShiType.upper]! +
        s * lingShiRates[LingShiType.supreme]!);
  }

  static Future<void> applyBreakthroughIfNeeded(Character player, int beforeLayer) async {
    final afterLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    if (afterLayer > beforeLayer) {
      debugPrint('🎉 玩家突破成功！层数 $beforeLayer → $afterLayer');

      await addLayerGrowth(player, beforeLayer, afterLayer);
      await ZongmenDiscipleService.syncAllRealmWithPlayer();
    }
  }

  static int getBaseHp(Character player) => player.baseHp;
  static int getBaseAtk(Character player) => player.baseAtk;
  static int getBaseDef(Character player) => player.baseDef;

  static double getTotalPercentHp(Character player) => player.extraHp;
  static double getTotalPercentAtk(Character player) => player.extraAtk;
  static double getTotalPercentDef(Character player) => player.extraDef;

  static int getHp(Character player) {
    final base = getBaseHp(player);
    final percent = getTotalPercentHp(player);
    return (base * (1 + percent)).round();
  }

  static int getAtk(Character player) {
    final base = getBaseAtk(player);
    final percent = getTotalPercentAtk(player);
    return (base * (1 + percent)).round();
  }

  static int getDef(Character player) {
    final base = getBaseDef(player);
    final percent = getTotalPercentDef(player);
    return (base * (1 + percent)).round();
  }

  static int getPower(Character player) {
    return calculatePower(
      hp: getHp(player),
      atk: getAtk(player),
      def: getDef(player),
    );
  }

  static Future<void> addLayerGrowth(Character player, int oldLayer, int newLayer) async {
    int hpGain = 0;
    int atkGain = 0;
    int defGain = 0;

    for (int i = oldLayer + 1; i <= newLayer; i++) {
      final stageIndex = (i - 1) ~/ 10;
      final stageMultiplier = 1 << stageIndex;
      hpGain += (75 * stageMultiplier);
      atkGain += (15 * stageMultiplier);
      defGain += (8 * stageMultiplier);
    }

    player.baseHp += hpGain;
    player.baseAtk += atkGain;
    player.baseDef += defGain;

    await updateFields({
      'baseHp': player.baseHp,
      'baseAtk': player.baseAtk,
      'baseDef': player.baseDef,
    });

    debugPrint('🆙 addLayerGrowth() → 新增层=$oldLayer → $newLayer，增加HP+$hpGain ATK+$atkGain DEF+$defGain');
  }
}
