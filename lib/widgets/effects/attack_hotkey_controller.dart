// 📄 lib/widgets/effects/attack_hotkey_controller.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/timer.dart' as f;
import 'package:flutter/services.dart';

// 适配器（都在 widgets/effects/）
import 'fireball_player_adapter.dart';
import 'player_lightning_chain_adapter.dart';
import 'player_meteor_rain_adapter.dart';

// 你的工程服务/模型
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

// 目标组件类型
import '../components/floating_island_dynamic_mover_component.dart';

enum _AttackKind { none, fireball, chain, meteor }

/// 统一热键控制器：一个 Q，按“已装备功法”自动释放 火球 / 雷链 / 流星坠
class AttackHotkeyController extends Component
    with KeyboardHandler, HasGameReference {
  final SpriteComponent host;

  // —— 三种技能的适配器 —— //
  final PlayerFireballAdapter fireball;
  final PlayerLightningChainAdapter lightning;
  final PlayerMeteorRainAdapter meteor;

  // 候选目标
  final List<PositionComponent> Function() candidatesProvider;

  // 键位：只用 Q（可覆盖）
  final Set<LogicalKeyboardKey> _hotkeys;

  // 公共冷却
  final f.Timer _cdTimer;
  bool _onCd = false;

  // 装备判定（按名字）
  final String attackSlotKey;
  final Set<String> _fireballNames;
  final Set<String> _chainNames;
  final Set<String> _meteorNames;
  final bool requireEquipped;
  final f.Timer _equipPoller;
  _AttackKind _equippedKind = _AttackKind.none;
  Map<String, Gongfa>? _idToAttack; // id -> Gongfa

  // ===== 火球：提前量所需 =====
  final double projectileSpeed; // 与 PlayerFireballAdapter.cast 的 speed 对齐
  final Map<PositionComponent, Vector2> _lastPos = {};
  final Map<PositionComponent, Vector2> _vel = {};

  // ===== 雷链：范围/跳数 =====
  final double castRange;   // 第一跳最大距离
  final double jumpRange;   // 后续跳跃最大距离
  final int maxJumps;       // 最大跳数（含第一跳）

  // ===== 流星坠：参数 =====
  final int    meteorCount;
  final double meteorSpread;
  final double meteorWarn;               // 兼容保留（实际调用传 0）
  final double meteorInterval;
  final double meteorExplosionRadius;
  final double meteorCastRange;          // ★ 施法最大距离

  static const bool _debug = false;

  AttackHotkeyController._({
    required this.host,
    required this.fireball,
    required this.lightning,
    required this.meteor,
    required this.candidatesProvider,
    required Set<LogicalKeyboardKey> hotkeys,
    required double cooldown,

    // 装备判定
    required this.attackSlotKey,
    required Set<String> fireballNames,
    required Set<String> chainNames,
    required Set<String> meteorNames,
    required this.requireEquipped,
    required double equipCheckInterval,

    // 火球
    required this.projectileSpeed,

    // 雷链
    required this.castRange,
    required this.jumpRange,
    required this.maxJumps,

    // 流星
    required this.meteorCount,
    required this.meteorSpread,
    required this.meteorWarn,
    required this.meteorInterval,
    required this.meteorExplosionRadius,
    required this.meteorCastRange,
  })  : _hotkeys = hotkeys,
        _cdTimer = f.Timer(cooldown, repeat: false),
        _fireballNames = fireballNames,
        _chainNames = chainNames,
        _meteorNames = meteorNames,
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

  /// 一行挂上（默认就用 Q）
  static AttackHotkeyController attach({
    required SpriteComponent host,
    required PlayerFireballAdapter fireball,
    required PlayerLightningChainAdapter lightning,
    required PlayerMeteorRainAdapter meteor,
    required List<PositionComponent> Function() candidatesProvider,

    Set<LogicalKeyboardKey> hotkeys = const {}, // 运行时兜底
    double cooldown = 0.8,

    // 装备判定（按名字）
    String attackSlotKey = 'attack',
    Set<String> fireballNames = const {'火球术', '火球', 'fireball', 'fire ball'},
    Set<String> chainNames = const {'雷链', '雷链术', '雷电链', 'chain lightning', 'chain-lightning'},
    Set<String> meteorNames = const {'流星坠','流星雨','meteor rain','meteor'},
    bool requireEquipped = true,
    double equipCheckInterval = 0.5,

    // 火球
    double projectileSpeed = 420.0,

    // 雷链
    double castRange = 320,
    double jumpRange = 240,
    int maxJumps = 6,

    // 流星
    int    meteorCount = 7,
    double meteorSpread = 140,
    double meteorWarn = 0.0,      // 兼容参数，实际调用强制 0
    double meteorInterval = 0.08,
    double meteorExplosionRadius = 68,
    double meteorCastRange = 320, // ★ 施法最大距离
  }) {
    final chosenHotkeys =
    hotkeys.isEmpty ? {LogicalKeyboardKey.keyQ} : hotkeys;

    final c = AttackHotkeyController._(
      host: host,
      fireball: fireball,
      lightning: lightning,
      meteor: meteor,
      candidatesProvider: candidatesProvider,
      hotkeys: chosenHotkeys,
      cooldown: cooldown,
      attackSlotKey: attackSlotKey,
      fireballNames:
      fireballNames.map((e) => e.trim().toLowerCase()).toSet(),
      chainNames:
      chainNames.map((e) => e.trim().toLowerCase()).toSet(),
      meteorNames:
      meteorNames.map((e) => e.trim().toLowerCase()).toSet(),
      requireEquipped: requireEquipped,
      equipCheckInterval: equipCheckInterval,
      projectileSpeed: projectileSpeed,
      castRange: castRange,
      jumpRange: jumpRange,
      maxJumps: maxJumps,
      meteorCount: meteorCount,
      meteorSpread: meteorSpread,
      meteorWarn: meteorWarn,
      meteorInterval: meteorInterval,
      meteorExplosionRadius: meteorExplosionRadius,
      meteorCastRange: meteorCastRange,
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
      case _AttackKind.meteor:
        _castMeteor();
        break;
      case _AttackKind.none:
        return true;
    }

    _onCd = true;
    _cdTimer.start();
    return true;
  }

  // ==================== 火球 ====================
  void _castFireball() {
    final fromW = host.absoluteCenter.clone();

    final target = _pickTargetWithinRange(range: double.infinity);
    Vector2 aimToW;

    if (target != null) {
      final vT = _vel[target] ?? Vector2.zero(); // 目标速度（世界）
      final lead =
      _predictIntercept(fromW, target.absoluteCenter.clone(), vT, projectileSpeed);
      aimToW = lead;
    } else {
      // 没有目标也要能释放：朝正右直飞 300 像素
      aimToW = fromW + Vector2(300, 0);
    }

    fireball.cast(
      to: aimToW,
      follow: target,                 // 只用于锁定中心估算；不拐弯
      speed: projectileSpeed,
      turnRateDegPerSec: 0,          // 不追踪
      maxDistance: 300,              // =“射程”
      explodeOnTimeout: true,
    );
  }

  // ==================== 雷链 ====================
  void _castChain() {
    final pool = candidatesProvider()
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();
    if (pool.isEmpty) return;

    final origin = host.absoluteCenter;

    // 第一跳：在 castRange 内优先 Boss，再最近
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

  // ==================== 流星坠（范围内优先Boss→其它→随机点） ====================
  void _castMeteor() {
    final poolAll = candidatesProvider()
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();

    final origin = host.absoluteCenter;
    final r2 = meteorCastRange * meteorCastRange;

    // 只考虑“范围内”的目标
    final inRangeBoss = <FloatingIslandDynamicMoverComponent>[];
    final inRangeOther = <FloatingIslandDynamicMoverComponent>[];

    for (final c in poolAll) {
      final d2 = c.absoluteCenter.distanceToSquared(origin);
      if (d2 > r2) continue;
      if (_isBoss(c)) {
        inRangeBoss.add(c);
      } else {
        inRangeOther.add(c);
      }
    }

    Vector2 center;

    if (inRangeBoss.isNotEmpty) {
      // 最近 Boss
      inRangeBoss.sort((a,b) =>
          a.absoluteCenter.distanceToSquared(origin)
              .compareTo(b.absoluteCenter.distanceToSquared(origin)));
      center = inRangeBoss.first.absoluteCenter.clone();
    } else if (inRangeOther.isNotEmpty) {
      // 最近其它
      inRangeOther.sort((a,b) =>
          a.absoluteCenter.distanceToSquared(origin)
              .compareTo(b.absoluteCenter.distanceToSquared(origin)));
      center = inRangeOther.first.absoluteCenter.clone();
    } else {
      // ✅ 范围内没有任何 move：在“施法圆”内随机一点（均匀分布）
      final rng = math.Random();
      final ang = rng.nextDouble() * math.pi * 2;
      final rr = math.sqrt(rng.nextDouble()) * meteorCastRange; // 均匀圆盘
      center = origin + Vector2(math.cos(ang), math.sin(ang))..scale(rr);
    }

    // 强制无预告圈
    meteor.castRain(
      centerWorld: center,
      count: meteorCount,
      spreadRadius: meteorSpread,
      warnTime: 0.0,
      interval: meteorInterval,
      explosionRadius: meteorExplosionRadius,
    );
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

    // 防止缓存不全
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
      if (_meteorNames.contains(name)) return _AttackKind.meteor;
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
        _vel[c] = (now - last) / dt; // 世界速度
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
      if (d2 > maxD2) continue;

      if (_isBoss(c)) {
        if (d2 < bestBossD2) { bestBossD2 = d2; bestBoss = c; }
      } else {
        if (d2 < bestOtherD2) { bestOtherD2 = d2; bestOther = c; }
      }
    }
    return bestBoss ?? bestOther;
  }
}
