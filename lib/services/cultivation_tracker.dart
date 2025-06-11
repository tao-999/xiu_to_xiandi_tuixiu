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
    final aptitude = PlayerStorage.calculateTotalElement(player.elements);
    final maxExp = getMaxExpByAptitude(aptitude);
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

      final gain = player.cultivationEfficiency * 1;
      final newExp = player.cultivation + gain;

      final aptitude = PlayerStorage.calculateTotalElement(player.elements);
      final maxExp = getMaxExpByAptitude(aptitude);
      player.cultivation = newExp.clamp(0, maxExp);

      final oldExp = (jsonDecode(jsonStr)['cultivation'] ?? 0.0) * 1.0;
      final oldTotalLayer = calculateCultivationLevel(oldExp).totalLayer;
      final newTotalLayer = calculateCultivationLevel(player.cultivation).totalLayer;

      if (newTotalLayer > oldTotalLayer) {
        for (int layer = oldTotalLayer + 1; layer <= newTotalLayer; layer++) {
          PlayerStorage.applyBreakthroughBonus(player, layer);
        }
      }

      await prefs.setString('playerData', jsonEncode(player.toJson()));

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
    final maxLevel = aptitude.clamp(1, maxPossibleLevel); // ✨ 砍掉 0.9
    final before = totalExpToLevel(maxLevel);
    final current = expNeededForLevel(maxLevel);
    return before + current;
  }

  static Future<void> _updateCultivationOnly(double cultivation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playerData') ?? '{}';
    final playerJson = jsonDecode(raw);
    playerJson['cultivation'] = cultivation;
    await prefs.setString('playerData', jsonEncode(playerJson));
  }

  static Future<void> safeAddExp(double addedExp, {void Function()? onUpdate}) async {
    stopTick();

    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final aptitude = PlayerStorage.calculateTotalElement(player.elements);
    final maxExp = getMaxExpByAptitude(aptitude);
    final oldLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    player.cultivation = (player.cultivation + addedExp).clamp(0, maxExp);
    final newLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    for (int layer = oldLayer + 1; layer <= newLayer; layer++) {
      PlayerStorage.applyBreakthroughBonus(player, layer);
    }

    await PlayerStorage.savePlayer(player);
    startGlobalTick();
    onUpdate?.call();
  }
}
