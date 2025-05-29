import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';

class CultivationTracker {
  static const String _expKey = 'cultivation_exp';
  static const String _loginTimeKey = 'lastOnlineTimestamp';
  static const double _qiPerSecond = 1.0;

  static double _baseExp = 0.0;
  static int _loginTimestamp = 0;
  static Timer? _tickTimer;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseExp = prefs.getDouble(_expKey) ?? 0.0;
    _loginTimestamp = prefs.getInt(_loginTimeKey) ?? DateTime.now().millisecondsSinceEpoch;

    _loginTimestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_loginTimeKey, _loginTimestamp);
  }

  static double get currentExp {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - _loginTimestamp) / 1000).floor();
    return _baseExp + seconds * _qiPerSecond;
  }

  static Future<void> saveCurrentExp() async {
    final prefs = await SharedPreferences.getInstance();
    final nowExp = currentExp;
    _baseExp = nowExp;
    _loginTimestamp = DateTime.now().millisecondsSinceEpoch;

    await prefs.setDouble(_expKey, _baseExp);
    await prefs.setInt(_loginTimeKey, _loginTimestamp);
  }

  static Future<void> savePlayerCultivation(double cultivation) async {
    _baseExp = cultivation;
    _loginTimestamp = DateTime.now().millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_expKey, _baseExp);
    await prefs.setInt(_loginTimeKey, _loginTimestamp);
  }

  static void startTickWithPlayer(
      Character player, {
        void Function()? onUpdate,
      }) {
    _tickTimer?.cancel();

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final startExp = _baseExp;

    int lastTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final seconds = ((now - startTime) / 1000).floor();

      final double efficiency = player.cultivationEfficiency;
      final generatedExp = startExp + seconds * _qiPerSecond * efficiency;
      print("generatedExp🤣====$efficiency");
      final maxExp = getMaxExpByAptitude(player.totalElement);

      if (generatedExp <= maxExp) {
        player.cultivation = generatedExp;
        _baseExp = generatedExp;
      } else {
        player.cultivation = maxExp;
        _baseExp = maxExp;
      }

      final newTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
      if (newTotalLayer > lastTotalLayer) {
        player.applyBreakthroughBonus();
        lastTotalLayer = newTotalLayer;
      }

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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerData', jsonEncode(player.toJson()));
    await savePlayerCultivation(player.cultivation);

    startTickWithPlayer(player, onUpdate: onUpdate);
  }
}
