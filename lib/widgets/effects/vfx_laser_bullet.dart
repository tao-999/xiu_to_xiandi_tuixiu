import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';

/// 子弹式“激光弹”(Laser Bullet)
/// - 从 startLocal 按 dirUnit * speed 飞行；每帧用“前一帧→当前帧”的线段与 AABB 相交检测
/// - 命中结算一次整伤 onceDamage，播放碎屑 + 球形电弧，随后销毁
/// - 可限制只命中 onlyHit（每束只打一个 move 场景）
/// - 渲染为“短尾迹”的子弹曳光：tip 在 pos，尾巴长度 tailLength 像素
class VfxLaserBullet extends PositionComponent with HasGameReference {
  // ===== 外部参数 =====
  final Vector2 startLocal;     // 出膛点（所在渲染层的本地坐标）
  final Vector2 dirUnit;        // 方向，已归一化
  final double speed;           // 像素/秒
  final double maxDistance;     // 最大飞行距离（命中前的上限）
  final double tailLength;      // 渲染尾迹长度（像素）
  final double width;           // 可视宽度（像素）
  final List<Color> palette;    // 从内到外的颜色（≥1）
  final double onceDamage;      // 单次整伤（与火球一致）
  final FloatingIslandPlayerComponent owner;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;
  final FloatingIslandDynamicMoverComponent? onlyHit; // 只命中该 mover（可空）

  // ===== 内部状态 =====
  Vector2 _pos;         // 子弹头部（tip）位置
  Vector2 _prev;        // 上一帧位置（用于线段相交）
  double _traveled = 0; // 已飞行距离
  bool _done = false;

  final Random _rng = Random();
  final Random _rng2 = Random();

  VfxLaserBullet({
    required this.startLocal,
    required this.dirUnit,
    required this.speed,
    required this.maxDistance,
    required this.tailLength,
    required this.width,
    required this.palette,
    required this.onceDamage,
    required this.owner,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    this.onlyHit,
    int? priority,
  })  : _pos = startLocal.clone(),
        _prev = startLocal.clone() {
    anchor = Anchor.center;
    size = Vector2.zero();
    if (priority != null) this.priority = priority;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 枪口微光（一次性小闪）
    parent?.add(_MuzzleFlash(
      position: _pos.clone(),
      radius: width * 0.9,
      color: (palette.length >= 2 ? palette[1] : palette.first).withOpacity(0.8),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done || dt <= 0) return;

    _prev = _pos.clone();
    final delta = dirUnit * (speed * dt);
    _pos += delta;
    _traveled += delta.length;

    // 到达最大射程：销毁
    if (_traveled >= maxDistance) {
      removeFromParent();
      return;
    }

    // 命中检测：用“上一帧位置→当前帧位置”的线段与 AABB 相交
    final parentRoot = parent ?? this;

    // 1) 若限定目标 → 只测该 mover
    if (onlyHit != null) {
      final m = onlyHit!;
      if (!m.isDead && m.isMounted) {
        final Rect aabb = _moverAabbLocal(m);
        final Rect expand = _expandRect(aabb, width * 0.5);
        final t = _segmentAabbFirstT(_prev, _pos, expand);
        if (t != null) {
          _applyHit(m, t);
          return;
        }
      }
      return;
    }

    // 2) 否则：扫描所有活着的 mover，取沿线“最先相交”的一个
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
      final t = _segmentAabbFirstT(_prev, _pos, expand);
      if (t != null && t < bestT) { bestT = t; best = m; }
    }
    if (best != null) {
      _applyHit(best, bestT);
    }
  }

  void _applyHit(FloatingIslandDynamicMoverComponent m, double tHit) {
    if (_done) return;
    _done = true;

    // 命中点（沿上一帧→当前帧的线段插值）
    final hit = _prev + (dirUnit * (speed * 0)) + ( _pos - _prev ) * tHit;

    // 结算整伤
    final dmg = onceDamage.isFinite ? onceDamage.clamp(1.0, 1e12) : 1.0;
    m.applyDamage(
      amount: dmg,
      killer: owner,
      logicalOffset: getLogicalOffset(),
      resourceBarKey: resourceBarKey,
    );

    // 命中特效：碎屑 + 球形电弧
    _spawnDebrisAt(hit);
    _spawnSphericalArcsOnMover(m);

    removeFromParent();
  }

  // —— 工具：把 mover AABB 转成与本层同坐标 —— //
  Rect _moverAabbLocal(FloatingIslandDynamicMoverComponent m) {
    final PositionComponent? lp =
    parent is PositionComponent ? parent as PositionComponent : null;
    Vector2 centerLocal = m.absoluteCenter;
    if (lp != null) centerLocal = lp.absoluteToLocal(centerLocal);

    final half = m.size / 2;
    return Rect.fromLTWH(
      centerLocal.x - half.x,
      centerLocal.y - half.y,
      m.size.x,
      m.size.y,
    );
  }

  Rect _expandRect(Rect r, double pad) =>
      Rect.fromLTWH(r.left - pad, r.top - pad, r.width + pad * 2, r.height + pad * 2);

  /// Liang–Barsky：线段 p0→p1 与 AABB 相交的首次 t（0..1），无则 null
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

  // —— 渲染：短尾迹（tip 在 _pos，尾巴反向） —— //
  @override
  void render(Canvas c) {
    super.render(c);

    // —— 计算“当前应显示”的尾迹长度：随飞行增长，上限 tailLength —— //
    final len = math.min(tailLength, _traveled + speed * 0.016); // 开枪瞬间不拉满
    final tip = Offset(_pos.x, _pos.y);
    final dir = Offset(dirUnit.x, dirUnit.y);

    // 渐变颜色：核心&尾巴主色
    final coreCol = palette.first;                              // 纯白核
    final tailCol = (palette.length >= 4 ? palette[3]           // 鲜红
        : (palette.length >= 2 ? palette[1] : palette.first));

    // —— 分段画“锥形短尾迹”：越靠近尾巴越细越透明 —— //
    // 6 段足够平滑；你要更短可以把 len 再调小（见适配器参数）
    const int segs = 6;
    for (int i = 0; i < segs; i++) {
      final f0 = i / segs;            // [0..1)，靠近尾巴
      final f1 = (i + 1) / segs;      // (0..1]，靠近弹头
      final a = tip - dir * (len * f1);
      final b = tip - dir * (len * f0);

      // 宽度从尾到头：0.35W → 1.00W；透明度也从低到高
      final w = width * (0.35 + 0.65 * (1.0 - f0));
      final alpha = 0.10 + 0.80 * (1.0 - f0);
      final col = Color.lerp(
        tailCol.withOpacity(alpha * 0.8),       // 尾部偏红、透明
        coreCol.withOpacity(alpha * 0.95),      // 头部偏白、亮
        1.0 - f0,
      )!;

      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w
        ..color = col;
      c.drawLine(a, b, paint);
    }

    // —— 子弹头辉光（小瓣） —— //
    final glowCol = (palette.length >= 2 ? palette[1] : coreCol);
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = glowCol.withOpacity(0.85);
    c.drawCircle(tip, width * 0.7, glow);

    // —— 弹头核心短亮线，增加“锐利感” —— //
    final head = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, width * 0.45)
      ..color = coreCol.withOpacity(0.95);
    final headFrom = tip - dir * (width * 0.9);
    c.drawLine(headFrom, tip, head);
  }

  // ================== 特效：碎屑 & 球形电弧 ==================
  List<Color> _filterNonWhite(List<Color> src) {
    return src.where((c) {
      final r = c.red, g = c.green, b = c.blue;
      return !(r >= 240 && g >= 240 && b >= 240);
    }).toList();
  }

  void _spawnDebrisAt(Vector2 posLocal) {
    final root = parent ?? this;
    final nonWhite = _filterNonWhite(palette);
    final count = 10 + _rng2.nextInt(8);
    root.add(_LaserDebrisBurst(
      position: posLocal.clone(),
      baseSize: width,
      count: count,
      palette: nonWhite.isNotEmpty ? nonWhite : [palette.last],
      dirUnit: dirUnit.clone(),
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
}

/// 枪口小闪光
class _MuzzleFlash extends PositionComponent {
  final double radius;
  final Color color;
  _MuzzleFlash({required Vector2 position, required this.radius, required this.color}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.zero();
  }
  double _life = 0.08, _max = 0.08;
  @override void update(double dt){ _life -= dt; if (_life<=0) removeFromParent(); }
  @override void render(Canvas c){
    final t = (_life/_max).clamp(0.0,1.0);
    final p = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = color.withOpacity(0.6*t);
    c.drawCircle(Offset.zero, radius*(1.0+0.6*(1.0-t)), p);
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

// ==== 球形电弧（挂在被击中 mover 上） ====
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
