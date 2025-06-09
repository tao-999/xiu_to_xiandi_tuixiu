import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class CultivationTracker {
  static const String _loginTimeKey = 'lastOnlineTimestamp';
  static Timer? _tickTimer;
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  /// 初始化时补算离线期间修为
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

  static void startGlobalTick() {
    if (_tickTimer != null && _tickTimer!.isActive) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('playerData');
      if (jsonStr == null) return;

      final player = Character.fromJson(jsonDecode(jsonStr));

      // ✅ 实时获取当前修为再加
      final gain = player.cultivationEfficiency * 1;
      final newExp = player.cultivation + gain;

      final maxExp = getMaxExpByAptitude(player.totalElement);
      player.cultivation = newExp.clamp(0, maxExp);

      final newTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;
      final oldTotalLayer = calculateCultivationLevel(
          (jsonDecode(jsonStr)['cultivation'] ?? 0.0) * 1.0
      ).totalLayer;

      if (newTotalLayer > oldTotalLayer) {
        player.applyBreakthroughBonus();
      }

      await prefs.setString('playerData', jsonEncode(player.toJson()));

      // ✅ 通知监听者
      for (final listener in _listeners) {
        listener();
      }
    });
  }

  static void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  static double getMaxExpByAptitude(int aptitude) {
    final maxPossibleLevel = CultivationConfig.realms.length * CultivationConfig.levelsPerRealm;
    final maxLevel = (aptitude * 0.9).floor().clamp(1, maxPossibleLevel);
    final before = totalExpToLevel(maxLevel);
    final current = expNeededForLevel(maxLevel);
    return before + current;
  }

  static Future<void> applyRewardedExp(
      double addedExp, {
        void Function()? onUpdate,
      }) async {
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
        player.applyBreakthroughBonus();
        hasBreakthrough = true;
      }

      final updateMap = {'cultivation': player.cultivation};
      if (hasBreakthrough) {
        updateMap.addAll({
          'hp': player.hp.toDouble(),
          'atk': player.atk.toDouble(),
          'def': player.def.toDouble(),
        });
      }

      await PlayerStorage.updateFields(updateMap);
      onUpdate?.call();
    }
  }

  static Future<void> _updateCultivationOnly(double cultivation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playerData') ?? '{}';
    final playerJson = jsonDecode(raw);
    playerJson['cultivation'] = cultivation;
    await prefs.setString('playerData', jsonEncode(playerJson));
  }

  static Future<void> safeAddExp(double addedExp, {void Function()? onUpdate}) async {
    stopTick(); // ✅ 不能 await，因为是 void

    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final maxExp = getMaxExpByAptitude(player.totalElement);
    player.cultivation = (player.cultivation + addedExp).clamp(0, maxExp);

    await PlayerStorage.savePlayer(player);

    startGlobalTick(); // ✅ 同样别 await

    onUpdate?.call();
  }

}
