// 📄 lib/logic/combat/boss_reward_registry.dart
//
// 作用：按 boss.type 分发到各自的“死亡奖励”函数。
// 用法：
//  1) 启动时注册：BossRewardRegistry.register('boss_1', Boss1CollisionHandler.onKilled);
//  2) Boss 被打到 0 血时调用：BossRewardRegistry.dispatch(...);
//
// 备注：奖励函数签名统一：FutureOr<void> Function(BossKillContext, FloatingIslandDynamicMoverComponent)

import 'dart:async';
import 'package:flutter/material.dart';                 // GlobalKey, debugPrint
import 'package:flame/components.dart';                 // Vector2

import '../../widgets/components/floating_island_player_component.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';
import '../../widgets/components/resource_bar.dart';

/// 结算上下文：谁击杀、当前地图逻辑偏移、资源条 key（用于刷新）
class BossKillContext {
  final FloatingIslandPlayerComponent player;
  final Vector2 logicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  const BossKillContext({
    required this.player,
    required this.logicalOffset,
    required this.resourceBarKey,
  });
}

/// 每个 Boss 的“死亡奖励回调”签名
typedef BossOnKilled = FutureOr<void> Function(
    BossKillContext ctx,
    FloatingIslandDynamicMoverComponent boss,
    );

/// 注册表本体：按 boss.type 路由到对应的 onKilled()
class BossRewardRegistry {
  static final Map<String, BossOnKilled> _map = <String, BossOnKilled>{};

  /// 注册（重复注册会覆盖）
  static void register(String bossType, BossOnKilled fn) {
    _map[bossType] = fn;
  }

  /// 一次性批量注册
  static void registerAll(Map<String, BossOnKilled> entries) {
    _map.addAll(entries);
  }

  /// 反注册
  static bool unregister(String bossType) => _map.remove(bossType) != null;

  /// 是否已注册
  static bool has(String bossType) => _map.containsKey(bossType);

  /// 清空所有注册
  static void clear() => _map.clear();

  /// 分发：根据 boss.type 调用对应回调；未注册则安静返回（或打印一条日志）
  static Future<void> dispatch({
    required String bossType,
    required BossKillContext ctx,
    required FloatingIslandDynamicMoverComponent boss,
  }) async {
    if (bossType.isEmpty) {
      debugPrint('[BossRewardRegistry] skip: empty bossType');
      return;
    }
    final handler = _map[bossType];
    if (handler == null) {
      debugPrint('[BossRewardRegistry] no handler for type="$bossType"');
      return;
    }
    // 兼容 sync/async 的回调
    await Future.sync(() => handler(ctx, boss));
  }
}
