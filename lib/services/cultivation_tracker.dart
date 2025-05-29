import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';

class CultivationTracker {
  static const String _loginTimeKey = 'lastOnlineTimestamp';
  static const double _qiPerSecond = 1.0;

  static Timer? _tickTimer;

  /// 初始化时补算登录期间修为（只修改 player.cultivation）
  static Future<void> initWithPlayer(Character player) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt(_loginTimeKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - lastLogin) / 1000).floor();

    final added = seconds * _qiPerSecond * player.cultivationEfficiency;
    final maxExp = getMaxExpByAptitude(player.totalElement);
    player.cultivation = (player.cultivation + added).clamp(0, maxExp);

    await prefs.setInt(_loginTimeKey, now);
    await _updateCultivationOnly(player.cultivation);
  }

  static void startTickWithPlayer(
      Character player, {
        void Function()? onUpdate,
      }) {
    _tickTimer?.cancel();

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final startExp = player.cultivation;
    int lastTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final seconds = ((now - startTime) / 1000).floor();
      final gain = seconds * _qiPerSecond * player.cultivationEfficiency;
      final newExp = (startExp + gain);

      final maxExp = getMaxExpByAptitude(player.totalElement);
      player.cultivation = newExp.clamp(0, maxExp);

      final newTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
      if (newTotalLayer > lastTotalLayer) {
        player.applyBreakthroughBonus();
        lastTotalLayer = newTotalLayer;
      }

      await _updateCultivationOnly(player.cultivation);

      onUpdate?.call();
    });
  }

  static void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  static double getMaxExpByAptitude(int aptitude) {
    final maxLevel = (aptitude * 0.9).floor().clamp(1, 189);
    return totalExpToLevel(maxLevel + 1);
  }

  static Future<void> applyRewardedExp(
      Character player,
      double addedExp, {
        void Function()? onUpdate,
      }) async {
    stopTick();

    final maxExp = getMaxExpByAptitude(player.totalElement);
    final oldStage = calculateCultivationLevel(player.cultivation);

    if (player.cultivation >= maxExp) {
      print('【溢出被禁止】无法增加修为');
    } else {
      player.cultivation += addedExp;
      if (player.cultivation > maxExp) {
        player.cultivation = maxExp;
      }

      final newStage = calculateCultivationLevel(player.cultivation);
      final isBreak = newStage.totalLayer > oldStage.totalLayer;

      if (isBreak) {
        player.applyBreakthroughBonus();
      }
    }

    await _updateCultivationOnly(player.cultivation);
    startTickWithPlayer(player, onUpdate: onUpdate);
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
