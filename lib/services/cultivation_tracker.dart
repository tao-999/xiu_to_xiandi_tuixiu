import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class CultivationTracker {
  static const String _loginTimeKey = 'lastOnlineTimestamp';
  static Timer? _tickTimer;

  /// 初始化时补算登录期间修为（只修改 player.cultivation）
  static Future<void> initWithPlayer(Character player) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt(_loginTimeKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - lastLogin) / 1000).floor();

    final added = seconds * player.cultivationEfficiency;
    final maxExp = getMaxExpByAptitude(player.totalElement);
    player.cultivation = (player.cultivation + added).clamp(0, maxExp);

    await prefs.setInt(_loginTimeKey, now);
    await _updateCultivationOnly(player.cultivation);
  }

  /// 每秒持续增长修为（增长值 = 秒数 × cultivationEfficiency）
  static void startTickWithPlayer({void Function()? onUpdate}) {
    _tickTimer?.cancel();

    int lastTotalLayer = -1;
    double startExp = 0.0;
    int startTime = DateTime.now().millisecondsSinceEpoch;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('playerData');
      if (jsonStr == null) return;

      final player = Character.fromJson(jsonDecode(jsonStr));
      // 初始化起始修为与境界层数（只执行一次）
      if (lastTotalLayer == -1) {
        lastTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
        startExp = player.cultivation;
        startTime = DateTime.now().millisecondsSinceEpoch;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final seconds = ((now - startTime) / 1000).floor();
      final gain = seconds * player.cultivationEfficiency;
      final newExp = startExp + gain;

      final maxExp = getMaxExpByAptitude(player.totalElement);
      player.cultivation = newExp.clamp(0, maxExp);

      final newTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
      if (newTotalLayer > lastTotalLayer) {
        player.applyBreakthroughBonus();
        lastTotalLayer = newTotalLayer;
      }

      // 保存全量数据，确保持续更新
      await prefs.setString('playerData', jsonEncode(player.toJson()));

      onUpdate?.call();
    });
  }

  static void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// 根据资质，计算修为上限（每一层乘1.5，初始值为100）
  static double getMaxExpByAptitude(int aptitude) {
    final maxLevel = (aptitude * 0.9).floor().clamp(1, 189);
    final before = totalExpToLevel(maxLevel);
    final current = expNeededForLevel(maxLevel);
    return before + current;
  }

  /// 发放额外修为（例如奖励、翻倍等）
  static Future<void> applyRewardedExp(
      double addedExp, {
        void Function()? onUpdate,
      }) async {
    stopTick();

    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final maxExp = getMaxExpByAptitude(player.totalElement);
    final oldStage = calculateCultivationLevel(player.cultivation);

    if (player.cultivation >= maxExp) {
      print('【溢出被禁止】无法增加修为');
    } else {
      player.cultivation = (player.cultivation + addedExp).clamp(0, maxExp);

      final newStage = calculateCultivationLevel(player.cultivation);
      bool hasBreakthrough = false;

      if (newStage.totalLayer > oldStage.totalLayer) {
        player.applyBreakthroughBonus(); // 会修改 hp、atk、def
        hasBreakthrough = true;
      }

      // ✅ 更新字段，必须加上突破属性！
      final Map<String, dynamic> updateMap = {
        'cultivation': player.cultivation,
      };

      if (hasBreakthrough) {
        updateMap.addAll({
          'hp': player.hp,
          'atk': player.atk,
          'def': player.def,
        });
      }

      await PlayerStorage.updateFields(updateMap);
    }

    startTickWithPlayer(onUpdate: onUpdate);
  }

  /// ✅ 通用封装：只保存修为字段，不动其他字段
  static Future<void> _updateCultivationOnly(double cultivation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playerData') ?? '{}';
    final playerJson = jsonDecode(raw);

    playerJson['cultivation'] = cultivation;
    await prefs.setString('playerData', jsonEncode(playerJson));
  }
}
