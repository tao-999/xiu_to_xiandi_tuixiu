import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/timer.dart' as f;
import 'package:flutter/services.dart';

import 'fireball_player_adapter.dart';
import 'player_lightning_chain_adapter.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_dynamic_mover_component.dart';

enum _AttackKind { none, fireball, chain }

class AttackHotkeyController extends Component
    with KeyboardHandler, HasGameReference {
  final SpriteComponent host;
  final PlayerFireballAdapter fireball;
  final PlayerLightningChainAdapter lightning;

  final List<PositionComponent> Function() candidatesProvider;

  // 键位：只用 Q，允许外部覆盖
  final Set<LogicalKeyboardKey> _hotkeys;

  // 公共冷却
  final f.Timer _cdTimer;
  bool _onCd = false;

  // 装备判定
  final String attackSlotKey;
  final Set<String> _fireballNames;
  final Set<String> _chainNames;
  final bool requireEquipped;
  final f.Timer _equipPoller;
  _AttackKind _equippedKind = _AttackKind.none;
  Map<String, Gongfa>? _idToAttack; // id -> Gongfa

  // 目标速度采样（火球提前量）
  final double projectileSpeed; // 与 fireball.cast 的 speed 对齐
  final Map<PositionComponent, Vector2> _lastPos = {};
  final Map<PositionComponent, Vector2> _vel = {};

  // 雷链参数
  final double castRange;   // 第一跳
  final double jumpRange;   // 后续跳跃
  final int maxJumps;

  static const bool _debug = false;

  AttackHotkeyController._({
    required this.host,
    required this.fireball,
    required this.lightning,
    required this.candidatesProvider,
    required Set<LogicalKeyboardKey> hotkeys,
    required double cooldown,

    // 装备判定
    required this.attackSlotKey,
    required Set<String> fireballNames,
    required Set<String> chainNames,
    required this.requireEquipped,
    required double equipCheckInterval,

    // 火球
    required this.projectileSpeed,

    // 雷链
    required this.castRange,
    required this.jumpRange,
    required this.maxJumps,
  })  : _hotkeys = hotkeys,
        _cdTimer = f.Timer(cooldown, repeat: false),
        _fireballNames = fireballNames,
        _chainNames = chainNames,
        _equipPoller = f.Timer(equipCheckInterval, repeat: true) {
    _cdTimer.onTick = () => _onCd = false;
    _equipPoller.onTick = () {
      () async {
        _equippedKind = await _detectEquippedKind();
        if (_debug) {
          // ignore: avoid_print
          print('[AttackHotkey] equipped=$_equippedKind');
        }
      }();
    };
  }

  /// 一行挂上（默认 Q 一个键，自动识别火球/雷链）
  static AttackHotkeyController attach({
    required SpriteComponent host,
    required PlayerFireballAdapter fireball,
    required PlayerLightningChainAdapter lightning,
    required List<PositionComponent> Function() candidatesProvider,

    Set<LogicalKeyboardKey> hotkeys = const {}, // 运行时兜底
    double cooldown = 0.8,

    String attackSlotKey = 'attack',
    Set<String> fireballNames = const {'火球术', '火球', 'fireball', 'fire ball'},
    Set<String> chainNames = const {
      '雷链', '雷链术', '雷电链', 'chain lightning', 'chain-lightning'
    },
    bool requireEquipped = true,
    double equipCheckInterval = 0.5,

    double projectileSpeed = 420.0, // 火球飞行速度
    double castRange = 320,         // 雷链第一跳
    double jumpRange = 240,         // 雷链后续跳
    int maxJumps = 6,
  }) {
    final chosenHotkeys =
    hotkeys.isEmpty ? {LogicalKeyboardKey.keyQ} : hotkeys;

    final c = AttackHotkeyController._(
      host: host,
      fireball: fireball,
      lightning: lightning,
      candidatesProvider: candidatesProvider,
      hotkeys: chosenHotkeys,
      cooldown: cooldown,
      attackSlotKey: attackSlotKey,
      fireballNames:
      fireballNames.map((e) => e.trim().toLowerCase()).toSet(),
      chainNames: chainNames.map((e) => e.trim().toLowerCase()).toSet(),
      requireEquipped: requireEquipped,
      equipCheckInterval: equipCheckInterval,
      projectileSpeed: projectileSpeed,
      castRange: castRange,
      jumpRange: jumpRange,
      maxJumps: maxJumps,
    );
    (host.parent ?? host).add(c);
    return c;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureIdCache();
    _equippedKind = await _detectEquippedKind();
    _equipPoller.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cdTimer.update(dt);
    _equipPoller.update(dt);
    _sampleVelocities(dt); // 火球提前量采样
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;
    if (!_hotkeys.contains(event.logicalKey)) return false;

    if (_onCd) return true;
    if (requireEquipped && _equippedKind == _AttackKind.none) return true;

    switch (_equippedKind) {
      case _AttackKind.fireball:
        _castFireball();
        break;
      case _AttackKind.chain:
        _castChain();
        break;
      case _AttackKind.none:
        return true;
    }

    _onCd = true;
    _cdTimer.start();
    return true;
  }

  // ======== 火球：跟你原控制器保持一致 ========
  void _castFireball() {
    final fromW = host.absoluteCenter.clone();

    final target = _pickTargetWithinRange(range: double.infinity);
    Vector2 aimToW;

    if (target != null) {
      final vT = _vel[target] ?? Vector2.zero();
      final lead =
      _predictIntercept(fromW, target.absoluteCenter.clone(), vT, projectileSpeed);
      // 不限制最大距离；飞行范围交给 adapter 的 maxDistance（你那边已处理）
      aimToW = lead;
    } else {
      // 没目标也能发：朝右
      aimToW = fromW + Vector2(300, 0);
    }

    fireball.cast(
      to: aimToW,
      follow: target,
      speed: projectileSpeed,
      turnRateDegPerSec: 0,
      maxDistance: 300,        // 和你火球 attach 的 range 对齐
      explodeOnTimeout: true,
    );
  }

  // ======== 雷链：选一条链然后丢给适配器 ========
  void _castChain() {
    final pool = candidatesProvider()
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();
    if (pool.isEmpty) return;

    final origin = host.absoluteCenter;

    // 第一跳：在 castRange 内优先 Boss 再最近
    FloatingIslandDynamicMoverComponent? pickFirst() {
      double bestBoss = double.infinity;
      double bestOther = double.infinity;
      FloatingIslandDynamicMoverComponent? boss, other;
      final r2 = castRange * castRange;

      for (final c in pool) {
        final d2 = c.absoluteCenter.distanceToSquared(origin);
        if (d2 > r2) continue;
        final isBoss = _isBoss(c);
        if (isBoss) {
          if (d2 < bestBoss) { bestBoss = d2; boss = c; }
        } else {
          if (d2 < bestOther) { bestOther = d2; other = c; }
        }
      }
      return boss ?? other;
    }

    final first = pickFirst();
    if (first == null) return;

    final chainTargets = <FloatingIslandDynamicMoverComponent>[first];
    var from = first.absoluteCenter;

    while (chainTargets.length < maxJumps) {
      double best = double.infinity;
      FloatingIslandDynamicMoverComponent? next;
      final r2 = jumpRange * jumpRange;

      for (final c in pool) {
        if (chainTargets.contains(c)) continue;
        final d2 = c.absoluteCenter.distanceToSquared(from);
        if (d2 > r2) continue;
        if (d2 < best) { best = d2; next = c; }
      }
      if (next == null) break;
      chainTargets.add(next);
      from = next.absoluteCenter;
    }

    lightning.castChain(targets: chainTargets);
  }

  // ========== 装备判定 ==========
  Future<void> _ensureIdCache() async {
    if (_idToAttack != null) return;
    final all = await GongfaCollectedStorage.getAllGongfa();
    _idToAttack = {
      for (final g in all)
        if (g.type == GongfaType.attack) g.id: g,
    };
  }

  Future<_AttackKind> _detectEquippedKind() async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return _AttackKind.none;

    final techMap = (p.techniquesMap as Map<String, List<String>>?) ?? const {};
    final ids = techMap[attackSlotKey] ?? const <String>[];
    if (ids.isEmpty) return _AttackKind.none;

    await _ensureIdCache();

    // 确保缓存覆盖完整
    bool refresh = false;
    for (final id in ids) {
      if (!(_idToAttack?.containsKey(id) ?? false)) { refresh = true; break; }
    }
    if (refresh) {
      _idToAttack = null;
      await _ensureIdCache();
    }

    for (final id in ids) {
      final g = _idToAttack?[id];
      final name = g?.name.trim().toLowerCase();
      if (name == null) continue;
      if (_fireballNames.contains(name)) return _AttackKind.fireball;
      if (_chainNames.contains(name)) return _AttackKind.chain;
    }
    return _AttackKind.none;
  }

  // ========== 工具 ==========
  bool _isBoss(PositionComponent c) {
    try {
      final t = (c as dynamic).type?.toString().toLowerCase();
      if (t != null) return t.contains('boss');
    } catch (_) {}
    return c.runtimeType.toString().toLowerCase().contains('boss');
  }

  void _sampleVelocities(double dt) {
    if (dt <= 0) return;
    final list = candidatesProvider();
    for (final c in list) {
      final now = c.absoluteCenter;
      final last = _lastPos[c];
      if (last != null) {
        _vel[c] = (now - last) / dt;
      }
      _lastPos[c] = now.clone();
    }
  }

  // 解方程：(v·v - s^2)t^2 + 2(r·v)t + r·r = 0，取最小正根
  Vector2 _predictIntercept(Vector2 shooter, Vector2 target, Vector2 v, double s) {
    final r = target - shooter;
    final a = v.dot(v) - s * s;
    final b = 2 * r.dot(v);
    final c = r.dot(r);

    double? t;
    const eps = 1e-6;
    if (a.abs() < eps) {
      if (b.abs() < eps) return target;
      final t0 = -c / b;
      if (t0 > 0) t = t0;
    } else {
      final disc = b * b - 4 * a * c;
      if (disc >= 0) {
        final sqrtD = math.sqrt(disc.toDouble());
        final t1 = (-b - sqrtD) / (2 * a);
        final t2 = (-b + sqrtD) / (2 * a);
        final cand = <double>[t1, t2]..removeWhere((x) => x <= 0);
        if (cand.isNotEmpty) t = cand.reduce(math.min);
      }
    }
    return t == null ? target : target + v * t;
  }

  PositionComponent? _pickTargetWithinRange({required double range}) {
    final list = candidatesProvider();
    if (list.isEmpty) return null;

    final origin = host.absoluteCenter;
    final maxD2 = range.isFinite ? range * range : double.infinity;

    PositionComponent? bestBoss;
    double bestBossD2 = double.infinity;

    PositionComponent? bestOther;
    double bestOtherD2 = double.infinity;

    for (final c in list) {
      if (identical(c, host)) continue;

      final d2 = c.absoluteCenter.distanceToSquared(origin);
      if (d2 > maxD2) continue; // 只看范围内

      if (_isBoss(c)) {
        if (d2 < bestBossD2) { bestBossD2 = d2; bestBoss = c; }
      } else {
        if (d2 < bestOtherD2) { bestOtherD2 = d2; bestOther = c; }
      }
    }
    return bestBoss ?? bestOther;
  }
}
