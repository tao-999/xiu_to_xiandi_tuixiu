import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/resources_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_disciple_service.dart';
import '../utils/cultivation_level.dart';
import '../utils/lingshi_util.dart';
import 'cultivation_tracker.dart';

class PlayerStorage {
  static const _playerKey = 'playerData';

  /// 精准更新 playerData 中的单个字段（推荐方式）
  static Future<void> updateField(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json[key] = value;
    await prefs.setString(_playerKey, jsonEncode(json));
  }

  /// 批量更新字段
  static Future<void> updateFields(Map<String, dynamic> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    json.addAll(fields);
    await prefs.setString(_playerKey, jsonEncode(json));
  }

  /// 获取整个 player 对象
  static Future<Character?> getPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey);
    if (raw == null) return null;
    return Character.fromJson(jsonDecode(raw));
  }

  /// 读取 playerData 中指定字段（返回 int，默认 0）
  static Future<int> getIntField(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    return (json[key] ?? 0) as int;
  }

  /// 新增：读取 BigInt 类型字段（默认 BigInt.zero）
  static Future<BigInt> getBigIntField(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    final value = json[key];
    return value != null ? BigInt.parse(value.toString()) : BigInt.zero;
  }

  /// 泛型读取任意字段（可选）
  static Future<T?> getField<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playerKey) ?? '{}';
    final json = jsonDecode(raw);
    return json[key] as T?;
  }

  /// ✨ 通用战斗力计算（用于角色、怪物等）
  static int calculatePower({
    required int hp,
    required int atk,
    required int def,
  }) {
    return (hp * 0.4 + atk * 2 + def * 1.5).toInt();
  }

  /// 🌱 获取当前玩家的境界总层数（练气1重 = 1，筑基1重 = 10 ...）
  static Future<int> getCultivationLayer() async {
    final player = await getPlayer();
    if (player == null) return 1;
    return calculateCultivationLevel(player.cultivation).totalLayer;
  }

  /// 💪 获取当前玩家尺寸倍率
  static Future<double> getSizeMultiplier() async {
    final layer = await getCultivationLayer();
    return 1.0 + (layer - 1) * 0.005;
  }

  /// 💰 使用灵石提升修为（全面支持 BigInt）
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

    // ✅ 扣除灵石
    await ResourcesStorage.subtract('spiritStoneLow', l);
    await ResourcesStorage.subtract('spiritStoneMid', m);
    await ResourcesStorage.subtract('spiritStoneHigh', h);
    await ResourcesStorage.subtract('spiritStoneSupreme', s);

    // ✅ 添加修为
    final addedExp = calculateAddedExp(low: l, mid: m, high: h, supreme: s);
    final player = await getPlayer(); // 这里只是为了获取 currentCultivation + applyBreakthrough，不需要 resources

    if (player == null) {
      onUpdate?.call();
      return;
    }

    final beforeLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    await CultivationTracker.safeAddExp(addedExp);

    await applyBreakthroughIfNeeded(player, beforeLayer);
    onUpdate?.call();
  }

  /// 根据各级灵石数量，计算预计可增加的修为（支持 BigInt）
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

  /// 🎯 检查是否突破，并统一刷新属性（用 calculateBaseAttributes）
  static Future<void> applyBreakthroughIfNeeded(Character player, int beforeLayer) async {
    final afterLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    if (afterLayer > beforeLayer) {
      debugPrint('🎉 玩家突破成功！层数 $beforeLayer → $afterLayer');

      // ✅ 重新计算基础属性
      calculateBaseAttributes(player);

      // ✅ 保存基础属性字段
      await updateFields({
        'baseHp': player.baseHp,
        'baseAtk': player.baseAtk,
        'baseDef': player.baseDef,
      });

      await ZongmenDiscipleService.syncAllRealmWithPlayer();
    }
  }

  /// 🔢 获取当前玩家的五行资质总和
  static int calculateTotalElement(Map<String, int> elements) {
    return elements.values.fold(0, (a, b) => a + b);
  }

  /// 📈 获取属性成长倍率（用于突破加成等）
  static double calculateGrowthMultiplier(Map<String, int> elements) {
    final total = calculateTotalElement(elements);
    return 1 + total / 100;
  }

  /// 🔰 获取玩家基础气血 / 攻击 / 防御
  static int getBaseHp(Character player) => player.baseHp;
  static int getBaseAtk(Character player) => player.baseAtk;
  static int getBaseDef(Character player) => player.baseDef;

  /// 🔰 获取玩家装备气血 / 攻击 / 防御
  static int getExtraHp(Character player) => player.extraHp;
  static int getExtraAtk(Character player) => player.extraAtk;
  static int getExtraDef(Character player) => player.extraDef;

  /// 🔰 获取玩家丹药气血 / 攻击 / 防御
  static int getPillHp(Character player) => player.pillBonusHp;
  static int getPillAtk(Character player) => player.pillBonusAtk;
  static int getPillDef(Character player) => player.pillBonusDef;

  /// 🔰 获取总气血 / 攻击 / 防御（仅用于战力计算或合并展示）
  static int getHp(Character player) =>
      getBaseHp(player) + getExtraHp(player) + getPillHp(player);

  static int getAtk(Character player) =>
      getBaseAtk(player) + getExtraAtk(player) + getPillAtk(player);

  static int getDef(Character player) =>
      getBaseDef(player) + getExtraDef(player) + getPillDef(player);

  /// 🔰 获取战力（统一从这里算，内部合并）
  static int getPower(Character player) {
    return calculatePower(
      hp: getHp(player),
      atk: getAtk(player),
      def: getDef(player),
    );
  }

  /// 🧬 统一属性计算（支持每10层翻倍 + 资质成长倍率）
  static Future<void> calculateBaseAttributes(Character player) async {
    final totalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
    final factor = calculateGrowthMultiplier(player.elements);

    const baseHpInit = 100;
    const baseAtkInit = 20;
    const baseDefInit = 10;

    int hpGain = 0;
    int atkGain = 0;
    int defGain = 0;

    for (int i = 1; i <= totalLayer; i++) {
      final stageIndex = (i - 1) ~/ 10;
      final stageMultiplier = 1 << stageIndex;

      hpGain += (50 * stageMultiplier);
      atkGain += (10 * stageMultiplier);
      defGain += (5 * stageMultiplier);
    }

    player.baseHp = baseHpInit + (hpGain * factor).round();
    player.baseAtk = baseAtkInit + (atkGain * factor).round();
    player.baseDef = baseDefInit + (defGain * factor).round();

    debugPrint('📊 calculateBaseAttributes() → 层=$totalLayer 倍率=${factor.toStringAsFixed(2)} → '
        'HP=${player.baseHp}, ATK=${player.baseAtk}, DEF=${player.baseDef}');

    await updateFields({
      'baseHp': player.baseHp,
      'baseAtk': player.baseAtk,
      'baseDef': player.baseDef,
    });
  }

  /// 🧙‍♂️ 穿戴武器后，根据武器属性（百分比）更新 extra 属性
  static Future<void> applyAllEquippedAttributesWith() async {
    final player = await getPlayer();
    if (player == null) return;

    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(player.id);

    int totalExtraHp = 0;
    int totalExtraAtk = 0;
    int totalExtraDef = 0;

    for (final weapon in equipped) {
      totalExtraHp += (player.baseHp * weapon.hpBoost / 100).round();
      totalExtraAtk += (player.baseAtk * weapon.attackBoost / 100).round();
      totalExtraDef += (player.baseDef * weapon.defenseBoost / 100).round();
    }

    player.extraHp = totalExtraHp;
    player.extraAtk = totalExtraAtk;
    player.extraDef = totalExtraDef;

    debugPrint('🧮 [属性加成更新] 装备数=${equipped.length} → HP +$totalExtraHp, ATK +$totalExtraAtk, DEF +$totalExtraDef');

    await updateFields({
      'extraHp': totalExtraHp,
      'extraAtk': totalExtraAtk,
      'extraDef': totalExtraDef,
    });
  }

  /// 🥣 吞丹！根据类型和数量，叠加到角色加成属性中
  static Future<void> applyPillBonus({
    required String type, // 'attack' | 'defense' | 'health'
    required int bonusPerPill,
    required int count,
  }) async {
    final player = await getPlayer();
    if (player == null) return;

    final totalBonus = bonusPerPill * count;

    switch (type) {
      case 'health':
        player.pillBonusHp += totalBonus;
        await updateField('pillBonusHp', player.pillBonusHp);
        break;
      case 'attack':
        player.pillBonusAtk += totalBonus;
        await updateField('pillBonusAtk', player.pillBonusAtk);
        break;
      case 'defense':
        player.pillBonusDef += totalBonus;
        await updateField('pillBonusDef', player.pillBonusDef);
        break;
      default:
        debugPrint('❌ 未知丹药类型：$type');
    }

    debugPrint('🍷 吞丹成功 → 类型=$type，数量=$count，累计加成=$totalBonus');
  }

}
