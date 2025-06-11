import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/bigint_extensions.dart'; // ✅ 使用 clamp 扩展

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

  /// ✅ 初始化时补算离线期间修为（已 BigInt 化）
  static Future<void> initWithPlayer(Character player) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt(_loginTimeKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - lastLogin) / 1000).floor();

    final added = BigInt.from((seconds * player.cultivationEfficiency).floor());
    final aptitude = PlayerStorage.calculateTotalElement(player.elements);
    final maxExp = getMaxExpByAptitude(aptitude);

    player.cultivation = (player.cultivation + added).clamp(BigInt.zero, maxExp);

    await prefs.setInt(_loginTimeKey, now);
    await _updateCultivationOnly(player.cultivation);
  }

  /// ✅ 启动全局 1 秒 tick
  static void startGlobalTick() {
    if (_tickTimer != null && _tickTimer!.isActive) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('playerData');
      if (jsonStr == null) return;

      final player = Character.fromJson(jsonDecode(jsonStr));

      final BigInt gain = BigInt.from(player.cultivationEfficiency.floor());
      final BigInt newExp = player.cultivation + gain;

      final aptitude = PlayerStorage.calculateTotalElement(player.elements);
      final BigInt maxExp = getMaxExpByAptitude(aptitude);
      player.cultivation = newExp.clamp(BigInt.zero, maxExp);

      final oldExp = BigInt.tryParse(jsonDecode(jsonStr)['cultivation'].toString()) ?? BigInt.zero;
      final oldLayer = calculateCultivationLevel(oldExp).totalLayer;
      final newLayer = calculateCultivationLevel(player.cultivation).totalLayer;

      if (newLayer > oldLayer) {
        PlayerStorage.calculateBaseAttributes(player);
      }

      await prefs.setString('playerData', jsonEncode(player.toJson()));

      for (final listener in _listeners) {
        listener();
      }
    });
  }

  /// ✅ 停止 tick
  static void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// ✅ 根据资质获取最大经验（BigInt）
  static BigInt getMaxExpByAptitude(int aptitude) {
    final maxPossibleLevel = CultivationConfig.realms.length * CultivationConfig.levelsPerRealm;
    final cappedLevel = aptitude.clamp(1, maxPossibleLevel);
    return totalExpToLevel(cappedLevel + 1);
  }

  /// ✅ 只更新修为（不动其他字段）
  static Future<void> _updateCultivationOnly(BigInt cultivation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playerData') ?? '{}';
    final json = jsonDecode(raw);
    json['cultivation'] = cultivation.toString(); // ✅ BigInt → String
    await prefs.setString('playerData', jsonEncode(json));
  }

  /// ✅ 安全添加修为（如吃丹、剧情奖励等）
  static Future<void> safeAddExp(BigInt addedExp, {void Function()? onUpdate}) async {
    stopTick();

    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final aptitude = PlayerStorage.calculateTotalElement(player.elements);
    final BigInt maxExp = getMaxExpByAptitude(aptitude); // 👈 应该是 totalExpToLevel(apt + 1)

    final BigInt current = player.cultivation;
    final BigInt capped = current + addedExp;

    // ✅ 修正裁切方式：允许等于 maxExp，不能再超
    player.cultivation = capped > maxExp ? maxExp : capped;

    // 🧠 检查是否突破
    final oldLayer = calculateCultivationLevel(current).totalLayer;
    final newLayer = calculateCultivationLevel(player.cultivation).totalLayer;

    if (newLayer > oldLayer) {
      PlayerStorage.calculateBaseAttributes(player); // 重新计算属性
    }

    await PlayerStorage.savePlayer(player);
    startGlobalTick();
    onUpdate?.call();
  }
}
