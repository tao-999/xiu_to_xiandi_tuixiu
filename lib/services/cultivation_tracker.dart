import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/bigint_extensions.dart'; // ✅ clamp扩展

class CultivationTracker {
  static const String _loginTimeKey = 'lastOnlineTimestamp';
  static Timer? _tickTimer;
  static final List<VoidCallback> _listeners = [];

  /// ✅ 注册监听器
  static void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  /// ✅ 移除监听器
  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  /// ✅ 离线修为补算
  static Future<void> initWithPlayer(Character player) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt(_loginTimeKey) ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - lastLogin) / 1000).floor();

    final added = BigInt.from((seconds * player.cultivationEfficiency).floor());
    final aptitude = player.aptitude;
    final maxExp = getMaxExpByAptitude(aptitude);

    final oldLayer = calculateCultivationLevel(player.cultivation).totalLayer;
    player.cultivation = (player.cultivation + added).clamp(BigInt.zero, maxExp);
    final newLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    if (newLayer > oldLayer) {
      await PlayerStorage.addLayerGrowth(player, oldLayer, newLayer);
    }

    await prefs.setInt(_loginTimeKey, now);
    await _updateCultivationOnly(player.cultivation);
  }

  /// ✅ 启动全局tick
  static void startGlobalTick() {
    if (_tickTimer != null && _tickTimer!.isActive) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('playerData');
      if (jsonStr == null) return;

      final player = Character.fromJson(jsonDecode(jsonStr));
      final BigInt gain = BigInt.from(player.cultivationEfficiency.floor());
      final BigInt newExp = player.cultivation + gain;

      final aptitude = player.aptitude;
      final BigInt maxExp = getMaxExpByAptitude(aptitude);
      player.cultivation = newExp.clamp(BigInt.zero, maxExp);

      final oldExp = BigInt.tryParse(jsonDecode(jsonStr)['cultivation'].toString()) ?? BigInt.zero;
      final oldLayer = calculateCultivationLevel(oldExp).totalLayer;
      final newLayer = calculateCultivationLevel(player.cultivation).totalLayer;

      if (newLayer > oldLayer) {
        await PlayerStorage.addLayerGrowth(player, oldLayer, newLayer);
      }

      await prefs.setString('playerData', jsonEncode(player.toJson()));
      for (final listener in _listeners) {
        listener();
      }
    });
  }

  /// ✅ 停止tick
  static void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// ✅ 获取最大经验
  static BigInt getMaxExpByAptitude(int aptitude) {
    final maxPossibleLevel = CultivationConfig.realms.length * CultivationConfig.levelsPerRealm;
    final cappedLevel = aptitude.clamp(1, maxPossibleLevel);
    return totalExpToLevel(cappedLevel + 1);
  }

  /// ✅ 更新修为
  static Future<void> _updateCultivationOnly(BigInt cultivation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playerData') ?? '{}';
    final json = jsonDecode(raw);
    json['cultivation'] = cultivation.toString();
    await prefs.setString('playerData', jsonEncode(json));
  }

  /// ✅ 安全增加修为
  static Future<void> safeAddExp(BigInt addedExp, {void Function()? onUpdate}) async {
    stopTick();

    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final int aptitude = player.aptitude;
    final BigInt maxExp = getMaxExpByAptitude(aptitude);

    final BigInt current = player.cultivation;
    final BigInt capped = current + addedExp;
    final BigInt newCultivation = capped > maxExp ? maxExp : capped;
    player.cultivation = newCultivation;

    final oldLayer = calculateCultivationLevel(current).totalLayer;
    final newLayer = calculateCultivationLevel(newCultivation).totalLayer;

    final Map<String, dynamic> updatedFields = {
      'cultivation': newCultivation.toString(),
    };

    if (newLayer > oldLayer) {
      await PlayerStorage.addLayerGrowth(player, oldLayer, newLayer);
      debugPrint('🎉 safeAddExp → 突破成功！层数 $oldLayer → $newLayer');
    }

    await PlayerStorage.updateFields(updatedFields);

    startGlobalTick();
    onUpdate?.call();
  }
}
