// 📄 lib/widgets/combat/fireball_hotkey_controller.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/timer.dart' as f;
import 'package:flutter/services.dart';

import 'fireball_player_adapter.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';

class FireballHotkeyController extends Component
    with KeyboardHandler, HasGameReference {
  final SpriteComponent host;

  // ⚠️ 语义：range = 火球最大飞行距离（攻击范围），不影响能否释放
  final double range;

  final PlayerFireballAdapter fireball;
  final Set<LogicalKeyboardKey> hotkeys;
  final List<PositionComponent> Function() candidatesProvider;

  // 冷却
  final f.Timer _cdTimer;
  bool _onCd = false;

  // 装备判定（按名字）
  final String attackSlotKey;
  final Set<String> expectedAttackNames;
  final bool requireEquipped;
  final f.Timer _equipPoller;
  bool _equipped = false;
  Map<String, Gongfa>? _idToAttack;

  // 目标速度采样（用于提前量）
  final double projectileSpeed; // 与适配器的 speed 保持一致
  final Map<PositionComponent, Vector2> _lastPos = {};
  final Map<PositionComponent, Vector2> _vel = {};

  static const bool _debug = false;

  FireballHotkeyController._({
    required this.host,
    required this.fireball,
    required this.range,
    required this.hotkeys,
    required this.candidatesProvider,
    required double cooldown,
    required this.attackSlotKey,
    required this.expectedAttackNames,
    required this.requireEquipped,
    required double equipCheckInterval,
    required this.projectileSpeed,
  })  : _cdTimer = f.Timer(cooldown, repeat: false),
        _equipPoller = f.Timer(equipCheckInterval, repeat: true) {
    _cdTimer.onTick = () => _onCd = false;
    _equipPoller.onTick = () {
      () async {
        _equipped = await _checkEquippedByName();
        if (_debug) {
          // ignore: avoid_print
          print('[FireballHotkey] equipped=$_equipped');
        }
      }();
    };
  }

  /// 一行挂上（range 仅用于“飞多远”，不影响能否释放）
  static FireballHotkeyController attach({
    required SpriteComponent host,
    required PlayerFireballAdapter fireball,
    required double range,
    required List<PositionComponent> Function() candidatesProvider,
    Set<LogicalKeyboardKey> hotkeys = const {},
    double cooldown = 0.8,

    // 装备判定（按名字）
    String attackSlotKey = 'attack',
    Set<String> expectedAttackNames = const {'火球术', '火球', 'fireball', 'fire ball'},
    bool requireEquipped = true,
    double equipCheckInterval = 0.5,

    // 与 PlayerFireballAdapter.cast 的 speed 对齐
    double projectileSpeed = 420.0,
  }) {
    final c = FireballHotkeyController._(
      host: host,
      fireball: fireball,
      range: range,
      hotkeys: hotkeys.isEmpty ? {LogicalKeyboardKey.keyQ} : hotkeys,
      candidatesProvider: candidatesProvider,
      cooldown: cooldown,
      attackSlotKey: attackSlotKey,
      expectedAttackNames:
      expectedAttackNames.map((e) => e.trim().toLowerCase()).toSet(),
      requireEquipped: requireEquipped,
      equipCheckInterval: equipCheckInterval,
      projectileSpeed: projectileSpeed,
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
    _sampleVelocities(dt); // 每帧记录候选目标速度（世界坐标）
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;
    if (!hotkeys.contains(event.logicalKey)) return false;

    // ✅ 只看装备&冷却，跟距离无关
    if (requireEquipped && !_equipped) return false;
    if (_onCd) return true;

    final fromW = host.absoluteCenter.clone();

    // 选择一个最近目标（不做距离门槛）
    final target = _pickTargetWithinRange();
    Vector2 aimToW;

    if (target != null) {
      final vT = _vel[target] ?? Vector2.zero(); // 目标速度（世界）
      final lead =
      _predictIntercept(fromW, target.absoluteCenter.clone(), vT, projectileSpeed);
      // 落点裁到“最大飞行距离”以内
      aimToW = _clampToMaxDistance(fromW, lead, range);
    } else {
      // 没有目标也要能释放：朝正右直飞 range 距离
      aimToW = fromW + Vector2(range, 0);
    }

    if (_debug) {
      // ignore: avoid_print
      print('[FireballHotkey] CAST -> $aimToW (from=$fromW, max=$range)');
    }

    // 直飞（不追踪）；把“攻击范围=最大飞行距离”传下去
    fireball.cast(
      to: aimToW,
      follow: target,                 // 只用于锁定中心半径估算；不拐弯
      speed: projectileSpeed,
      turnRateDegPerSec: 0,          // 不追踪
      maxDistance: range,            // 🧨 关键：攻击范围 = 最大飞行距离
      explodeOnTimeout: true,
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

  // ========== 速度采样 & 提前量 ==========
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

  // 把落点裁剪到“最大飞行距离”之内
  Vector2 _clampToMaxDistance(Vector2 from, Vector2 to, double maxD) {
    final d = (to - from);
    final len = d.length;
    if (len <= maxD || len == 0) return to;
    return from + d * (maxD / len);
  }

  bool _isBoss(PositionComponent c) {
    try {
      final t = (c as dynamic).type?.toString().toLowerCase();
      if (t != null) return t.contains('boss');
    } catch (_) {}
    return c.runtimeType.toString().toLowerCase().contains('boss');
  }

  PositionComponent? _pickTargetWithinRange() {
    final list = candidatesProvider();
    if (list.isEmpty) return null;

    final origin = host.absoluteCenter;
    final maxD2 = range * range;

    PositionComponent? bestBoss;
    double bestBossD2 = double.infinity;

    PositionComponent? bestOther;
    double bestOtherD2 = double.infinity;

    for (final c in list) {
      if (identical(c, host)) continue;

      final d2 = c.absoluteCenter.distanceToSquared(origin);
      if (d2 > maxD2) continue; // 只看攻击范围内的

      if (_isBoss(c)) {
        if (d2 < bestBossD2) { bestBossD2 = d2; bestBoss = c; }
      } else {
        if (d2 < bestOtherD2) { bestOtherD2 = d2; bestOther = c; }
      }
    }
    return bestBoss ?? bestOther;
  }

}
