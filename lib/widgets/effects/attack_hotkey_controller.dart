// 📄 lib/widgets/effects/attack_hotkey_controller.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/timer.dart' as f;
import 'package:flutter/services.dart';

// 适配器（都在 widgets/effects/）
import 'fireball_player_adapter.dart';
import 'player_lightning_chain_adapter.dart';
import 'player_meteor_rain_adapter.dart';
import 'player_laser_adapter.dart';

// 你的工程服务/模型
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/attack_gongfa_equip_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

// 目标组件类型
import '../components/floating_island_dynamic_mover_component.dart';

enum _AttackKind { none, fireball, chain, meteor, laser }

/// 统一热键控制器：Q 键点按一次释放一次（激光与其它技能一致），按下即进入 CD
/// 冷却时间与攻速(APS)绑定：此版本把 attackSpeed 当“冷却秒数”
class AttackHotkeyController extends Component
    with KeyboardHandler, HasGameReference {
  final SpriteComponent host;

  // —— 四种技能适配器 —— //
  final PlayerFireballAdapter fireball;
  final PlayerLightningChainAdapter lightning;
  final PlayerMeteorRainAdapter meteor;
  final PlayerLaserAdapter laser;

  // 候选目标
  final List<PositionComponent> Function() candidatesProvider;

  // 键位：默认 Q
  final Set<LogicalKeyboardKey> _hotkeys;

  // 冷却：动态时长一次性 Timer
  final double baseCooldown;
  f.Timer? _cdTimer;
  bool _onCd = false;

  // 装备判定
  final String attackSlotKey;
  final Set<String> _fireballNames;
  final Set<String> _chainNames;
  final Set<String> _meteorNames;
  final Set<String> _laserNames;
  final bool requireEquipped;
  final f.Timer _equipPoller;
  _AttackKind _equippedKind = _AttackKind.none;
  Map<String, Gongfa>? _idToAttack; // id -> Gongfa

  // ===== 火球提前量所需 =====
  final double projectileSpeed;
  final Map<PositionComponent, Vector2> _lastPos = {};
  final Map<PositionComponent, Vector2> _vel = {};

  // ===== 雷链 =====
  final double castRange;
  final double jumpRange;
  final int maxJumps;

  // ===== 流星坠 =====
  final double meteorSpread;
  final double meteorWarn;
  final double meteorInterval;
  final double meteorExplosionRadius;
  final double meteorCastRange;

  // ===== 激光参数（单发版本） =====
  final double laserMaxRange;     // 自动寻向/默认朝右的最大长度
  final double laserTickInterval; // 兼容字段（适配器里可不用）
  final double laserHoldMax;      // 兼容字段（不再使用）

  static const bool _debug = false;

  AttackHotkeyController._({
    required this.host,
    required this.fireball,
    required this.lightning,
    required this.meteor,
    required this.laser,
    required this.candidatesProvider,
    required Set<LogicalKeyboardKey> hotkeys,
    required this.baseCooldown,
    // 装备判定
    required this.attackSlotKey,
    required Set<String> fireballNames,
    required Set<String> chainNames,
    required Set<String> meteorNames,
    required Set<String> laserNames,
    required this.requireEquipped,
    required double equipCheckInterval,
    // 火球
    required this.projectileSpeed,
    // 雷链
    required this.castRange,
    required this.jumpRange,
    required this.maxJumps,
    // 流星
    required this.meteorSpread,
    required this.meteorWarn,
    required this.meteorInterval,
    required this.meteorExplosionRadius,
    required this.meteorCastRange,
    // 激光
    required this.laserMaxRange,
    required this.laserTickInterval,
    required this.laserHoldMax,
  })  : _hotkeys = hotkeys,
        _fireballNames = fireballNames,
        _chainNames = chainNames,
        _meteorNames = meteorNames,
        _laserNames = laserNames,
        _equipPoller = f.Timer(equipCheckInterval, repeat: true) {
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

  /// 一行挂上（默认用 Q）
  static AttackHotkeyController attach({
    required SpriteComponent host,
    required PlayerFireballAdapter fireball,
    required PlayerLightningChainAdapter lightning,
    required PlayerMeteorRainAdapter meteor,
    required PlayerLaserAdapter laser,
    required List<PositionComponent> Function() candidatesProvider,

    Set<LogicalKeyboardKey> hotkeys = const {},
    double cooldown = 0.8, // 兜底冷却

    // 装备判定
    String attackSlotKey = 'attack',
    Set<String> fireballNames = const {'火球术','火球','fireball','fire ball'},
    Set<String> chainNames = const {'雷链','雷链术','雷电链','chain lightning','chain-lightning'},
    Set<String> meteorNames = const {'流星坠','流星雨','meteor rain','meteor'},
    Set<String> laserNames  = const {'激光','激光束','雷射','laser','laser beam'},
    bool requireEquipped = true,
    double equipCheckInterval = 0.5,

    // 火球
    double projectileSpeed = 420.0,

    // 雷链
    double castRange = 320,
    double jumpRange = 240,
    int maxJumps = 6,

    // 流星
    double meteorSpread = 140,
    double meteorWarn = 0.0,
    double meteorInterval = 0.08,
    double meteorExplosionRadius = 68,
    double meteorCastRange = 320,

    // 激光（单发）
    double laserMaxRange = 520,
    double laserTickInterval = 0.06,
    double laserHoldMax = 6.0, // 兼容字段，不使用
  }) {
    final chosenHotkeys =
    hotkeys.isEmpty ? {LogicalKeyboardKey.keyQ} : hotkeys;

    final c = AttackHotkeyController._(
      host: host,
      fireball: fireball,
      lightning: lightning,
      meteor: meteor,
      laser: laser,
      candidatesProvider: candidatesProvider,
      hotkeys: chosenHotkeys,
      baseCooldown: cooldown,
      attackSlotKey: attackSlotKey,
      fireballNames:
      fireballNames.map((e) => e.trim().toLowerCase()).toSet(),
      chainNames:
      chainNames.map((e) => e.trim().toLowerCase()).toSet(),
      meteorNames:
      meteorNames.map((e) => e.trim().toLowerCase()).toSet(),
      laserNames:
      laserNames.map((e) => e.trim().toLowerCase()).toSet(),
      requireEquipped: requireEquipped,
      equipCheckInterval: equipCheckInterval,
      projectileSpeed: projectileSpeed,
      castRange: castRange,
      jumpRange: jumpRange,
      maxJumps: maxJumps,
      meteorSpread: meteorSpread,
      meteorWarn: meteorWarn,
      meteorInterval: meteorInterval,
      meteorExplosionRadius: meteorExplosionRadius,
      meteorCastRange: meteorCastRange,
      laserMaxRange: laserMaxRange,
      laserTickInterval: laserTickInterval,
      laserHoldMax: laserHoldMax,
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
    _cdTimer?.update(dt);
    _equipPoller.update(dt);
    _sampleVelocities(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // ✅ 所有技能统一：仅响应 KeyDown（点按一次释放一次）
    if (event is! KeyDownEvent) return false;
    if (!_hotkeys.contains(event.logicalKey)) return false;
    if (_onCd) return true;
    if (requireEquipped && _equippedKind == _AttackKind.none) return true;

    _onCd = true;               // ✅ 按下即进 CD
    _startCooldownByAPS();

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
      case _AttackKind.laser:
        _castLaserOnce();       // ✅ 单次释放
        break;
      case _AttackKind.none:
        _onCd = false;
        return true;
    }
    return true;
  }

  // ======== 冷却绑定 APS（attackSpeed 直接等于冷却秒数） ========
  void _startCooldownByAPS() {
    () async {
      final cd = await _calcEffectiveCooldown();
      _cdTimer?.stop();
      _cdTimer = f.Timer(cd, repeat: false);
      _cdTimer!.onTick = () => _onCd = false;
      _cdTimer!.start();
      if (_debug) {
        // ignore: avoid_print
        print('[AttackHotkey] cooldown=$cd');
      }
    }();
  }

  Future<double> _calcEffectiveCooldown() async {
    try {
      final p = await PlayerStorage.getPlayer();
      if (p == null) return baseCooldown;
      final g = await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id);
      final sec = g?.attackSpeed;
      if (sec == null || sec <= 0) return baseCooldown;
      return sec;
    } catch (_) {
      return baseCooldown;
    }
  }

  // ==================== 火球 ====================
  void _castFireball() {
    final fromW = host.absoluteCenter.clone();

    final target = _pickTargetWithinRange(range: double.infinity);
    Vector2 aimToW;

    if (target != null) {
      final vT = _vel[target] ?? Vector2.zero();
      final lead = _predictIntercept(
        fromW,
        target.absoluteCenter.clone(),
        vT,
        projectileSpeed,
      );
      aimToW = lead;
    } else {
      aimToW = fromW + Vector2(300, 0);
    }

    fireball.cast(
      to: aimToW,
      follow: target,
      speed: projectileSpeed,
      turnRateDegPerSec: 0,
      maxDistance: 300,
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

  // ==================== 流星坠 ====================
  void _castMeteor() {
    final poolAll = candidatesProvider()
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();

    final origin = host.absoluteCenter;
    final r2 = meteorCastRange * meteorCastRange;

    final inRangeBoss  = <FloatingIslandDynamicMoverComponent>[];
    final inRangeOther = <FloatingIslandDynamicMoverComponent>[];
    for (final c in poolAll) {
      final d2 = c.absoluteCenter.distanceToSquared(origin);
      if (d2 > r2) continue;
      (_isBoss(c) ? inRangeBoss : inRangeOther).add(c);
    }

    Vector2 center;
    if (inRangeBoss.isNotEmpty) {
      inRangeBoss.sort((a,b) =>
          a.absoluteCenter.distanceToSquared(origin)
              .compareTo(b.absoluteCenter.distanceToSquared(origin)));
      center = inRangeBoss.first.absoluteCenter.clone();
    } else if (inRangeOther.isNotEmpty) {
      inRangeOther.sort((a,b) =>
          a.absoluteCenter.distanceToSquared(origin)
              .compareTo(b.absoluteCenter.distanceToSquared(origin)));
      center = inRangeOther.first.absoluteCenter.clone();
    } else {
      center = _randomPointInRange(origin, meteorCastRange);
    }

    meteor.castRain(
      centerWorld: center,
      spreadRadius: meteorSpread,
      warnTime: 0.0,
      interval: meteorInterval,
      explosionRadius: meteorExplosionRadius,
    );
  }

  // ==================== 激光（单次点按释放，多束锁定/随机不重叠） ====================
  // 等级 → 束数（两级 +1 束，上限 6）
  int _extractLevelOfEquipped(Gongfa? g) {
    try {
      final dyn = g as dynamic;
      final v = dyn.level ?? dyn.lv ?? dyn.lvl ?? dyn.stage ?? dyn.grade ?? dyn.tier ?? 1;
      if (v is num) return v.clamp(1, 999).toInt();
    } catch (_) {}
    return 1;
  }

  Future<int> _beamCountForLevel() async {
    try {
      final p = await PlayerStorage.getPlayer();
      if (p == null) return 1;
      final g = await AttackGongfaEquipStorage.loadEquippedAttackBy(p.id);
      final lv = _extractLevelOfEquipped(g);
      return (1 + ((lv - 1) ~/ 2)).clamp(1, 6); // 1,1,2,2,3,3,4,4,5,5,6...
    } catch (_) { return 1; }
  }

  double _angleOf(Vector2 v) => math.atan2(v.y, v.x);
  double _normAngle(double a) {
    while (a <= -math.pi) a += math.pi * 2;
    while (a >   math.pi) a -= math.pi * 2;
    return a;
  }
  bool _angleTooClose(double a, List<double> used, double minSepRad) {
    for (final u in used) {
      final d = (_normAngle(a - u)).abs();
      if (d < minSepRad) return true;
    }
    return false;
  }

  void _castLaserOnce() async {
    // 束数
    final count = await _beamCountForLevel();

    // 候选目标：活着&在施法半径内
    final origin = host.absoluteCenter.clone();
    final pool = candidatesProvider()
        .whereType<FloatingIslandDynamicMoverComponent>()
        .where((c) => c.isMounted && !(c.isDead == true))
        .toList();

    final r2 = laserMaxRange * laserMaxRange;
    final inRange = <FloatingIslandDynamicMoverComponent>[];
    for (final c in pool) {
      if (c.absoluteCenter.distanceToSquared(origin) <= r2) {
        inRange.add(c);
      }
    }

    // Boss 优先 → 最近
    inRange.sort((a, b) {
      int bossA = _isBoss(a) ? 0 : 1;
      int bossB = _isBoss(b) ? 0 : 1;
      final byBoss = bossA.compareTo(bossB);
      if (byBoss != 0) return byBoss;
      final da = a.absoluteCenter.distanceToSquared(origin);
      final db = b.absoluteCenter.distanceToSquared(origin);
      return da.compareTo(db);
    });

    final targets = inRange.take(count).toList();
    final usedAngles = <double>[];

    // 1) 对每个目标：一束激光锁它（onlyHit），跟随目标，pierceAll=false
    for (final t in targets) {
      final dir = t.absoluteCenter - origin;
      final ang = _angleOf(dir);
      usedAngles.add(ang);

      await laser.cast(
        to: t.absoluteCenter.clone(),
        follow: t,
        overrideDuration: null,             // 用适配器的等级时长
        tickInterval: laserTickInterval,    // 兼容字段
        pierceAll: false,                   // ✅ 每束只命中一个
        priorityOffset: 80,
        onlyHit: t,                         // ✅ 只命中该 move
      );
    }

    // 2) 还需要补束：没有足够目标也要发（360° 随机但不重叠）
    final need = count - targets.length;
    if (need > 0) {
      final minSep = 12.0 * math.pi / 180.0; // 最小角距 12°
      final rand = math.Random();
      int added = 0;
      int attempts = 0;
      while (added < need && attempts < 256) {
        attempts++;
        final a = -math.pi + rand.nextDouble() * (math.pi * 2); // 360°
        if (_angleTooClose(a, usedAngles, minSep)) continue;
        usedAngles.add(a);

        final dir = Vector2(math.cos(a), math.sin(a));
        final to = origin + dir * laserMaxRange;

        await laser.cast(
          to: to,
          follow: null,                     // 无目标，定向射出
          overrideDuration: null,
          tickInterval: laserTickInterval,  // 兼容字段
          pierceAll: false,                 // ✅ 最多命中一个
          priorityOffset: 80,
          onlyHit: null,                    // ✅ 自动选“最近相交的一个”
        );
        added++;
      }
    }
  }

  // —— 工具函数 —— //
  Vector2 _randomPointInRange(Vector2 origin, double r) {
    final rng = math.Random();
    final ang = rng.nextDouble() * math.pi * 2;
    final rad = math.sqrt(rng.nextDouble()) * r;
    return origin + Vector2(math.cos(ang), math.sin(ang)) * rad;
  }

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
      if (_laserNames.contains(name))  return _AttackKind.laser;
    }
    return _AttackKind.none;
  }

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
