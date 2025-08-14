// 📄 lib/widgets/effects/vfx_laser_beam.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';

class VfxLaserBeam extends PositionComponent with HasGameReference {
  final Vector2 Function() getStartLocal;
  final Vector2 Function() getTargetLocal;
  final double maxLength;
  final double duration;
  final double width; // 【严格不超出】
  final double tickInterval;
  final double damagePerTick;
  final FloatingIslandPlayerComponent owner;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;
  final bool pierceAll; // 兼容参数（若 onlyHit==null 且想穿透才用到）

  /// 从内到外的颜色（至少 1 个）
  final List<Color> palette;

  /// ✅ 仅命中这个 mover（若为 null，则自动选择“最近相交的一个”）
  final FloatingIslandDynamicMoverComponent? onlyHit;

  double _age = 0.0;
  double _tickAcc = 0.0;
  Vector2 _p0 = Vector2.zero();
  Vector2 _p1 = Vector2.zero();
  Vector2 _dirUnit = Vector2(1, 0);
  final Random _rng = Random();

  VfxLaserBeam({
    required this.getStartLocal,
    required this.getTargetLocal,
    required this.maxLength,
    required this.duration,
    required this.width,
    required this.tickInterval,
    required this.damagePerTick,
    required this.owner,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    required this.palette,
    this.onlyHit,                      // ✅ 新增
    this.pierceAll = false,            // ✅ 默认不穿透
    int? priority,
  }) {
    anchor = Anchor.topLeft;
    size = Vector2.zero();
    if (priority != null) this.priority = priority;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _p0 = getStartLocal();
    final want = getTargetLocal();
    final dir = want - _p0;
    final len = dir.length;
    _dirUnit = len > 1e-6 ? dir / len : Vector2(1, 0);
    final useLen = min(len, max(0.0, maxLength));
    _p1 = _p0 + _dirUnit * useLen;

    _age += dt;
    if (_age >= duration) {
      removeFromParent();
      return;
    }

    _tickAcc += dt;
    if (_tickAcc >= tickInterval) {
      _tickAcc -= tickInterval;
      _dealDamageAlongBeam();
    }
  }

  void _dealDamageAlongBeam() {
    // ✅ 若只允许命中特定目标：只检测它
    if (onlyHit != null) {
      final m = onlyHit!;
      if (!m.isDead && m.isMounted) {
        final Rect aabb = _moverAabbLocal(m);
        final Rect expand = _expandRect(aabb, width * 0.5);
        final t = _segmentAabbFirstT(_p0, _p1, expand);
        if (t != null) {
          _applyHit(m, t);
        }
      }
      return; // 只命中这个，直接返回
    }

    // ✅ 否则在所有 mover 中挑“沿光束最近的一个”命中（不穿透）
    final parentRoot = parent ?? this;
    final movers = <FloatingIslandDynamicMoverComponent>[];
    void dfs(Component n) {
      for (final c in n.children) {
        if (c is FloatingIslandDynamicMoverComponent && !c.isDead && c.isMounted) {
          movers.add(c);
        }
        if (c.children.isNotEmpty) dfs(c);
      }
    }
    dfs(parentRoot);

    double bestT = double.infinity;
    FloatingIslandDynamicMoverComponent? best;
    for (final m in movers) {
      final Rect aabb = _moverAabbLocal(m);
      final Rect expand = _expandRect(aabb, width * 0.5);
      final t = _segmentAabbFirstT(_p0, _p1, expand);
      if (t != null && t < bestT) {
        bestT = t;
        best = m;
      }
    }
    if (best != null) {
      _applyHit(best, bestT);
      // 不再对其它目标结算（每束只打一个）
    } else if (pierceAll) {
      // （兼容老逻辑：想穿透才会继续）
      for (final m in movers) {
        final Rect aabb = _moverAabbLocal(m);
        final Rect expand = _expandRect(aabb, width * 0.5);
        final t = _segmentAabbFirstT(_p0, _p1, expand);
        if (t != null) _applyHit(m, t);
      }
    }
  }

  void _applyHit(FloatingIslandDynamicMoverComponent m, double tHit) {
    m.applyDamage(
      amount: damagePerTick,
      killer: owner,
      logicalOffset: getLogicalOffset(),
      resourceBarKey: resourceBarKey,
    );

    // 冲击点（沿光束 tHit 处）
    final impact = _p0 + (_p1 - _p0) * tHit;
    _spawnDebrisAt(impact);           // 碎屑（过滤白色）
    _spawnSphericalArcsOnMover(m);   // 球形电弧（挂在 mover 上）
  }

  Rect _moverAabbLocal(FloatingIslandDynamicMoverComponent m) {
    final PositionComponent? lp = parent is PositionComponent ? parent as PositionComponent : null;
    Vector2 centerLocal = m.absoluteCenter;
    if (lp != null) centerLocal = lp.absoluteToLocal(centerLocal);
    final half = m.size / 2;
    return Rect.fromLTWH(centerLocal.x - half.x, centerLocal.y - half.y, m.size.x, m.size.y);
  }

  Rect _expandRect(Rect r, double pad) =>
      Rect.fromLTWH(r.left - pad, r.top - pad, r.width + pad * 2, r.height + pad * 2);

  // 👉 返回与 AABB 的“首次相交”参数 t（0..1），无相交则 null
  double? _segmentAabbFirstT(Vector2 p0, Vector2 p1, Rect aabb) {
    final dx = p1.x - p0.x;
    final dy = p1.y - p0.y;
    double tMin = 0.0, tMax = 1.0;

    bool update(double p, double q) {
      if (p == 0) return q >= 0;
      final t = q / p;
      if (p < 0) {
        if (t > tMax) return false;
        if (t > tMin) tMin = t;
      } else {
        if (t < tMin) return false;
        if (t < tMax) tMax = t;
      }
      return true;
    }

    if (!update(-dx, p0.x - aabb.left)) return null;
    if (!update( dx, aabb.right - p0.x)) return null;
    if (!update(-dy, p0.y - aabb.top)) return null;
    if (!update( dy, aabb.bottom - p0.y)) return null;

    return tMax >= tMin ? tMin : null;
  }

  // ================== 视觉（保持 width 不变） ==================
  @override
  void render(Canvas c) {
    super.render(c);

    final p0 = Offset(_p0.x, _p0.y);
    final p1 = Offset(_p1.x, _p1.y);

    final nLayers = palette.length.clamp(1, 9);
    for (int i = 0; i < nLayers; i++) {
      final outerIdx = nLayers - 1 - i;
      final color = palette[outerIdx];
      final t = i / (nLayers - 1 == 0 ? 1 : (nLayers - 1));
      final strokeW = width * (1.0 - 0.5 * t); // 1.0..0.5，不超过 width
      final paint = Paint()
        ..blendMode = BlendMode.srcOver
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeW
        ..color = color.withOpacity((0.30 + 0.60 * (1.0 - t)).clamp(0.0, 1.0));
      c.drawLine(p0, p1, paint);
    }

    final corePaint = Paint()
      ..blendMode = BlendMode.srcOver
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.5, width * 0.35)
      ..color = palette.first.withOpacity(0.95);
    c.drawLine(p0, p1, corePaint);
  }

  // ================== 特效：碎屑 & 球形电弧 ==================
  final Random _rng2 = Random();

  void _spawnDebrisAt(Vector2 posLocal) {
    final root = parent ?? this;
    final nonWhite = _filterNonWhite(palette);
    final count = 10 + _rng2.nextInt(8);
    root.add(_LaserDebrisBurst(
      position: posLocal.clone(),
      baseSize: width,
      count: count,
      palette: nonWhite.isNotEmpty ? nonWhite : [palette.last],
      dirUnit: _dirUnit.clone(),
    ));
  }

  void _spawnSphericalArcsOnMover(FloatingIslandDynamicMoverComponent m) {
    final nonWhite = _filterNonWhite(palette);
    final mainColor = nonWhite.isNotEmpty
        ? nonWhite[_rng2.nextInt(nonWhite.length)]
        : (palette.length > 1 ? palette[1] : palette.first);
    final r = 0.5 * min(m.size.x, m.size.y) * 0.9;
    final bolts = 3 + _rng2.nextInt(3);
    final life = 0.12 + _rng2.nextDouble() * 0.16;
    m.add(_SphericalArcOnMover(
      radius: r,
      colorMain: mainColor,
      widthRef: width,
      bolts: bolts,
      life: life,
    ));
  }

  List<Color> _filterNonWhite(List<Color> src) {
    return src.where((c) {
      final r = c.red, g = c.green, b = c.blue;
      return !(r >= 240 && g >= 240 && b >= 240);
    }).toList();
  }
}

// ==== 碎屑 ====
class _LaserDebrisBurst extends PositionComponent {
  final double baseSize;
  final int count;
  final List<Color> palette;
  final Vector2 dirUnit;

  final Random _rng = Random();
  final List<_Shard> _shards = [];

  _LaserDebrisBurst({
    required Vector2 position,
    required this.baseSize,
    required this.count,
    required this.palette,
    required this.dirUnit,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final normal = Vector2(-dirUnit.y, dirUnit.x);
    for (int i = 0; i < count; i++) {
      final color = palette[_rng.nextInt(palette.length)];
      final speed = 180 + _rng.nextDouble() * 260;
      final spread = (_rng.nextDouble() - 0.5) * 0.9;
      final tangent = dirUnit * ((_rng.nextDouble() - 0.5) * 120);
      final v = (normal * (1.0 + spread))..scale(speed);
      final vel = v + tangent;
      final life = 0.18 + _rng.nextDouble() * 0.28;
      final size = baseSize * (0.10 + _rng.nextDouble() * 0.18);
      _shards.add(_Shard(
          pos: Vector2.zero(), vel: vel, life: life, maxLife: life, size: size, color: color));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final s in _shards) {
      if (s.life <= 0) continue;
      s.pos += s.vel * dt;
      s.vel *= 0.86;
      s.life -= dt;
    }
    if (_shards.every((s) => s.life <= 0)) removeFromParent();
  }

  @override
  void render(Canvas c) {
    super.render(c);
    for (final s in _shards) {
      if (s.life <= 0) continue;
      final t = (s.life / s.maxLife).clamp(0.0, 1.0);
      final alpha = 0.25 + 0.75 * t;
      final w = max(1.0, s.size * t);
      final p = Paint()
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w
        ..color = s.color.withOpacity(alpha);
      final from = Offset(s.pos.x, s.pos.y);
      final to = Offset(s.pos.x - s.vel.x * 0.02, s.pos.y - s.vel.y * 0.02);
      c.drawLine(from, to, p);
    }
  }
}

class _Shard {
  Vector2 pos, vel;
  double life, maxLife, size;
  Color color;
  _Shard({required this.pos, required this.vel, required this.life, required this.maxLife, required this.size, required this.color});
}

// ==== 球形电弧 ====
class _SphericalArcOnMover extends PositionComponent {
  final double radius;
  final Color colorMain;
  final double widthRef;
  final int bolts;
  double life;
  final double maxLife;

  final Random _rng = Random();
  final List<_ArcSeg> _arcs = [];
  final List<_Chord> _chords = [];

  _SphericalArcOnMover({
    required this.radius,
    required this.colorMain,
    required this.widthRef,
    this.bolts = 4,
    double life = 0.18,
  })  : life = life,
        maxLife = life {
    anchor = Anchor.center;
    size = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final parentPC = parent as PositionComponent?;
    if (parentPC != null) position = parentPC.size / 2;

    final outerCount = 4 + _rng.nextInt(4);
    for (int i = 0; i < outerCount; i++) {
      final rScale = 0.65 + _rng.nextDouble() * 0.35;
      final start = _rng.nextDouble() * pi * 2;
      final sweep = (0.5 + _rng.nextDouble() * 1.2) * (_rng.nextBool() ? 1 : -1);
      _arcs.add(_ArcSeg(start: start, sweep: sweep, rScale: rScale));
    }

    for (int i = 0; i < bolts; i++) {
      final angA = _rng.nextDouble() * pi * 2;
      final angB = angA + (pi * (0.5 + _rng.nextDouble() * 0.9)) * (_rng.nextBool() ? 1 : -1);
      final steps = 5 + _rng.nextInt(4);
      final jitterAmp = radius * 0.18;
      final pts = <Vector2>[];
      for (int s = 0; s <= steps; s++) {
        final f = s / steps;
        final ang = angA + (angB - angA) * f;
        final r = radius * (0.82 + _rng.nextDouble() * 0.18);
        final base = Offset(cos(ang) * r, sin(ang) * r);
        final jr = (_rng.nextDouble() - 0.5) * jitterAmp;
        final jt = (_rng.nextDouble() - 0.5) * jitterAmp * 0.6;
        final nx = -sin(ang), ny = cos(ang);
        final off = Offset(base.dx + nx * jt + cos(ang) * jr, base.dy + ny * jt + sin(ang) * jr);
        pts.add(Vector2(off.dx, off.dy));
      }
      _chords.add(_Chord(points: pts));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    for (final ch in _chords) {
      for (int i = 1; i < ch.points.length; i++) {
        ch.points[i] *= 0.992;
      }
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas c) {
    super.render(c);
    final t = (life / maxLife).clamp(0.0, 1.0);
    final col = colorMain;

    final strokeMain = max(1.0, widthRef * 0.12);
    final strokeGlow = max(1.0, widthRef * 0.22);

    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeGlow
      ..color = col.withOpacity(0.35 * t);
    final main = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeMain
      ..color = col.withOpacity(0.88 * t);

    for (final a in _arcs) {
      final r = radius * a.rScale;
      final rect = Rect.fromCircle(center: Offset.zero, radius: r);
      c.drawArc(rect, a.start, a.sweep, false, glow);
      c.drawArc(rect, a.start, a.sweep, false, main);
    }

    final pGlow = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeGlow * 0.6
      ..color = col.withOpacity(0.35 * t);
    final pMain = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeMain * 0.85
      ..color = col.withOpacity(0.95 * t);

    for (final ch in _chords) {
      final os = <Offset>[];
      for (final v in ch.points) os.add(Offset(v.x, v.y));
      c.drawPoints(ui.PointMode.polygon, os, pGlow);
      c.drawPoints(ui.PointMode.polygon, os, pMain);
    }
  }
}

class _ArcSeg { double start, sweep, rScale; _ArcSeg({required this.start, required this.sweep, required this.rScale}); }
class _Chord { List<Vector2> points; _Chord({required this.points}); }
