import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/timer.dart' as f;
import 'package:flutter/services.dart';

import 'player_lightning_chain_adapter.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_dynamic_mover_component.dart';

/// 雷链键位控制器（结构与 FireballHotkeyController 一致）
/// - 目标选择：优先 Boss，其次最近
/// - 起始施法距离 castRange；后续跳跃距离 jumpRange
class LightningChainHotkeyController extends Component
    with KeyboardHandler, HasGameReference {
  final SpriteComponent host;
  final PlayerLightningChainAdapter chain;
  final Set<LogicalKeyboardKey> hotkeys;

  final double castRange;          // 第一跳最大距离
  final double jumpRange;          // 后续跳跃最大距离
  final int maxJumps;              // 最大跳数（含第一跳）
  final double cooldown;           // 冷却

  // 装备判定（按名字）
  final String attackSlotKey;
  final Set<String> expectedAttackNames;
  final bool requireEquipped;
  final f.Timer _equipPoller;
  bool _equipped = false;
  Map<String, Gongfa>? _idToAttack;

  // 冷却
  final f.Timer _cdTimer;
  bool _onCd = false;

  // 候选目标
  final List<PositionComponent> Function() candidatesProvider;

  static const bool _debug = false;

  LightningChainHotkeyController._({
    required this.host,
    required this.chain,
    required this.hotkeys,
    required this.candidatesProvider,
    required this.castRange,
    required this.jumpRange,
    required this.maxJumps,
    required this.cooldown,
    required this.attackSlotKey,
    required this.expectedAttackNames,
    required this.requireEquipped,
    required double equipCheckInterval,
  })  : _cdTimer = f.Timer(cooldown, repeat: false),
        _equipPoller = f.Timer(equipCheckInterval, repeat: true) {
    _cdTimer.onTick = () => _onCd = false;
    _equipPoller.onTick = () {
      () async {
        _equipped = await _checkEquippedByName();
        if (_debug) {
          // ignore: avoid_print
          print('[LightningHotkey] equipped=$_equipped');
        }
      }();
    };
  }

  /// 一行挂上（与火球术 attach 风格一致）
  static LightningChainHotkeyController attach({
    required SpriteComponent host,
    required PlayerLightningChainAdapter chain,
    required List<PositionComponent> Function() candidatesProvider,

    // ✅ 别用 const {LogicalKeyboardKey.keyE}
    Set<LogicalKeyboardKey> hotkeys = const {},

    double castRange = 320,
    double jumpRange = 240,
    int maxJumps = 6,
    double cooldown = 1.0,

    String attackSlotKey = 'attack',
    Set<String> expectedAttackNames = const {
      '雷链', '雷链术', '雷电链', 'chain lightning', 'chain-lightning'
    },
    bool requireEquipped = true,
    double equipCheckInterval = 0.5,
  }) {
    // ✅ 运行时兜底
    final chosenHotkeys = hotkeys.isEmpty ? {LogicalKeyboardKey.keyE} : hotkeys;

    final c = LightningChainHotkeyController._(
      host: host,
      chain: chain,
      hotkeys: chosenHotkeys,                 // ← 用兜底后的
      candidatesProvider: candidatesProvider,
      castRange: castRange,
      jumpRange: jumpRange,
      maxJumps: maxJumps,
      cooldown: cooldown,
      attackSlotKey: attackSlotKey,
      expectedAttackNames:
      expectedAttackNames.map((e) => e.trim().toLowerCase()).toSet(),
      requireEquipped: requireEquipped,
      equipCheckInterval: equipCheckInterval,
    );
    (host.parent ?? host).add(c);
    return c;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureIdCache();
    _equipped = await _checkEquippedByName();
    _equipPoller.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cdTimer.update(dt);
    _equipPoller.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;
    if (!hotkeys.contains(event.logicalKey)) return false;
    if (requireEquipped && !_equipped) return false;
    if (_onCd) return true;

    final origin = host.absoluteCenter;
    final list = candidatesProvider();

    // 过滤出可打目标
    final targets = list
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();

    if (targets.isEmpty) return true;

    // 选择第一目标（castRange 内，优先 Boss）
    final first = _pickFirst(origin, targets, castRange);
    if (first == null) return true;

    // 继续选择链路
    final chainTargets = <FloatingIslandDynamicMoverComponent>[first];
    var from = first.absoluteCenter;

    while (chainTargets.length < maxJumps) {
      final next = _pickNext(from, targets, jumpRange, chainTargets);
      if (next == null) break;
      chainTargets.add(next);
      from = next.absoluteCenter;
    }

    if (_debug) {
      // ignore: avoid_print
      print('[LightningHotkey] path=${chainTargets.length}');
    }

    chain.castChain(
      targets: chainTargets,
      hopDelay: 0.04,          // 每跳间隔，纯手感
      thickness: 2.6,
      jaggedness: 10,
      segments: 18,
    );

    _onCd = true;
    _cdTimer.start();
    return true;
  }

  // ========== 装备判定（按名字） ==========
  Future<void> _ensureIdCache() async {
    if (_idToAttack != null) return;
    final all = await GongfaCollectedStorage.getAllGongfa();
    _idToAttack = {
      for (final g in all)
        if (g.type == GongfaType.attack) g.id: g,
    };
  }

  Future<bool> _checkEquippedByName() async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return false;
    final techMap = (p.techniquesMap as Map<String, List<String>>?) ?? const {};
    final ids = techMap[attackSlotKey] ?? const <String>[];
    if (ids.isEmpty) return false;

    await _ensureIdCache();
    bool refresh = false;
    for (final id in ids) {
      if (!(_idToAttack?.containsKey(id) ?? false)) {
        refresh = true;
        break;
      }
    }
    if (refresh) {
      _idToAttack = null;
      await _ensureIdCache();
    }

    for (final id in ids) {
      final g = _idToAttack?[id];
      final name = g?.name.trim().toLowerCase();
      if (name != null && expectedAttackNames.contains(name)) return true;
    }
    return false;
  }

  // ========== 目标选择 ==========
  bool _isBoss(PositionComponent c) {
    try {
      final t = (c as dynamic).type?.toString().toLowerCase();
      if (t != null) return t.contains('boss');
    } catch (_) {}
    return c.runtimeType.toString().toLowerCase().contains('boss');
  }

  FloatingIslandDynamicMoverComponent? _pickFirst(
      Vector2 origin,
      List<FloatingIslandDynamicMoverComponent> pool,
      double range,
      ) {
    final r2 = range * range;
    FloatingIslandDynamicMoverComponent? boss;
    double bossD2 = double.infinity;

    FloatingIslandDynamicMoverComponent? other;
    double otherD2 = double.infinity;

    for (final c in pool) {
      final d2 = c.absoluteCenter.distanceToSquared(origin);
      if (d2 > r2) continue;

      if (_isBoss(c)) {
        if (d2 < bossD2) {
          bossD2 = d2;
          boss = c;
        }
      } else {
        if (d2 < otherD2) {
          otherD2 = d2;
          other = c;
        }
      }
    }
    return boss ?? other;
  }

  FloatingIslandDynamicMoverComponent? _pickNext(
      Vector2 from,
      List<FloatingIslandDynamicMoverComponent> pool,
      double jumpR,
      List<FloatingIslandDynamicMoverComponent> used,
      ) {
    final r2 = jumpR * jumpR;
    FloatingIslandDynamicMoverComponent? best;
    double bestD2 = double.infinity;

    for (final c in pool) {
      if (used.contains(c)) continue;
      final d2 = c.absoluteCenter.distanceToSquared(from);
      if (d2 > r2) continue;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = c;
      }
    }
    return best;
  }
}
