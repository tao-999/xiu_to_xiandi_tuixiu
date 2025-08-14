// 📄 lib/widgets/effects/vfx_meteor_boulder.dart
//
// 🚀 陨石火焰流 + 真爆炸落地（无黑边 | 加法混合）
// 修正：尾部永远不超过头部体量与亮度 —— 通过宽度上限 + 衰减幂次 + 降低尾部模糊
//
// 用法同前：parent.add(VfxMeteorBoulder(...))

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

typedef VoidCallback = void Function();

class VfxMeteorBoulder extends PositionComponent {
  // —— 轨迹 —— //
  final Vector2 fromLocal;
  final Vector2 impactLocal;
  final double  fallTime;
  final double  delayStart;
  final VoidCallback? onImpact;
  final int? basePriority;

  // —— 视觉参数 —— //
  final double headRadius;
  final double coreBloom;
  final double glowBloom;
  final Color  colInner;
  final Color  colOuter;
  final bool   showImpactBurst;

  // —— 火焰丝带骨架 —— //
  final double backboneHz;
  final double tailSeconds;
  final double jitterAmp;
  final double streakWidth;

  // —— 尾部约束（这三条保证“头大尾小”） —— //
  final double tailMaxWidthRatio;   // 尾迹最大宽度 = headRadius * ratio  （默认 0.78）
  final double tailAlphaPow;        // 尾迹亮度幂次衰减（越大尾巴越暗）
  final double tailBlurScale;       // 尾迹模糊相对倍率（减小避免鼓包）

  // —— 点状拖焰 —— //
  final double dotHz;
  final int    dotMax;
  final double dotLifeMin;
  final double dotLifeMax;

  // —— 碎屑参数（落地用） —— //
  final int    debrisCount;
  final double debrisMinSize;
  final double debrisMaxSize;

  VfxMeteorBoulder({
    required this.fromLocal,
    required this.impactLocal,
    required this.fallTime,
    this.delayStart      = 0.0,
    this.onImpact,
    this.basePriority,

    this.headRadius      = 22.0,
    this.coreBloom       = 1.22,
    this.glowBloom       = 2.0,
    this.colInner        = const Color(0xFFFFF4C2),
    this.colOuter        = const Color(0xFFFF8400),
    this.showImpactBurst = true,

    this.backboneHz      = 120.0,
    this.tailSeconds     = 0.45,
    this.jitterAmp       = 10.0,
    this.streakWidth     = 42.0,

    // ✅ 关键三参数（控制尾部永远小于头部）
    this.tailMaxWidthRatio = 0.78,
    this.tailAlphaPow      = 1.8,
    this.tailBlurScale     = 1.05,

    this.dotHz           = 90.0,
    this.dotMax          = 70,
    this.dotLifeMin      = 0.20,
    this.dotLifeMax      = 0.35,

    this.debrisCount     = 22,
    this.debrisMinSize   = 4.0,
    this.debrisMaxSize   = 10.0,
  }) {
    anchor   = Anchor.center;
    position = fromLocal.clone();
    size     = Vector2.all(headRadius * 2);
  }

  // —— 状态 —— //
  double _t     = 0.0;
  double _delay = 0.0;
  Vector2? _lastPos;
  final Random _rng = Random();

  // 丝带骨架点 & 点状火焰
  final List<_Node> _backbone = [];
  final List<_Dot>  _dots     = [];

  // —— 画笔（全加法混合） —— //
  final Paint _pCore = Paint()..blendMode = BlendMode.plus;
  final Paint _pGlow = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 30);
  final Paint _pRibbon = Paint()
    ..blendMode = BlendMode.plus
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _pRibbonBlur = Paint()
    ..blendMode = BlendMode.plus
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12); // ⬅️ 降低模糊
  final Paint _pDot = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

  late final int _maxBackbone = (backboneHz * tailSeconds).ceil().clamp(12, 999);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_delay < delayStart) {
      _delay += dt;
      return;
    }

    _t += dt;
    final p  = (_t / fallTime).clamp(0.0, 1.0);
    final ep = _easeInCubic(p);

    final delta  = impactLocal - fromLocal;
    final newPos = fromLocal + delta * ep;

    final vel = (_lastPos == null) ? Vector2.zero() : (newPos - _lastPos!);
    final dir = vel.length2 == 0 ? (impactLocal - fromLocal).normalized() : vel.normalized();

    position = newPos;
    _lastPos = newPos.clone();

    _sampleBackbone(dt, dir);
    _spawnDots(dt, dir);

    for (final d in _dots) d.t += dt;
    _dots.removeWhere((d) => d.t >= d.life);
    if (_dots.length > dotMax) _dots.removeRange(0, _dots.length - dotMax);

    if (p >= 1.0) {
      if (showImpactBurst && parent != null) {
        parent!.add(MeteorExplosion(
          worldPos: impactLocal.clone(),
          baseRadius: headRadius,
          colInner: colInner,
          colOuter: colOuter,
          sparkCount: 26,
          debrisCount: debrisCount,
          debrisMinSize: debrisMinSize,
          debrisMaxSize: debrisMaxSize,
          basePriority: (basePriority ?? priority) + 1,
        ));
      }
      onImpact?.call();
      removeFromParent();
    }
  }

  void _sampleBackbone(double dt, Vector2 dir) {
    final wantNodes = (backboneHz * dt).clamp(0.0, 4.0);
    int n = wantNodes.floor();
    if (_rng.nextDouble() < (wantNodes - n)) n += 1;

    final normal = Vector2(-dir.y, dir.x);

    for (int i = 0; i < n; i++) {
      final back = (i + _rng.nextDouble()) * (streakWidth * 0.12);
      final pos  = position - dir * back;

      final jitter = (jitterAmp * (0.6 + _rng.nextDouble() * 0.8));
      final offset = normal * ((_rng.nextDouble() - 0.5) * 2.0 * jitter);

      _backbone.add(_Node(
        pos: pos + offset,
        width: streakWidth * (0.7 + _rng.nextDouble() * 0.5),
        t: 0.0,
      ));
    }

    for (final n in _backbone) {
      n.t += dt;
    }

    while (_backbone.length > _maxBackbone) {
      _backbone.removeAt(0);
    }
  }

  void _spawnDots(double dt, Vector2 dir) {
    final wantDots = (dotHz * dt).clamp(0.0, 6.0);
    int n = wantDots.floor();
    if (_rng.nextDouble() < (wantDots - n)) n += 1;

    for (int i = 0; i < n; i++) {
      final jitter = Vector2(
        (_rng.nextDouble() - 0.5) * headRadius * 0.8,
        (_rng.nextDouble() - 0.5) * headRadius * 0.8,
      );
      final pos = position - dir * (headRadius * (0.35 + _rng.nextDouble() * 0.9)) + jitter;
      final life = _lerp(dotLifeMin, dotLifeMax, _rng.nextDouble());
      final r    = headRadius * (0.35 + _rng.nextDouble() * 0.25); // ⬅️ 点状半径降到 ≤0.6H
      _dots.add(_Dot(pos, r, life));
    }
  }

  @override
  void render(Canvas c) {
    super.render(c);

    _renderRibbon(c);

    for (final d in _dots) {
      final k = (d.t / d.life).clamp(0.0, 1.0);
      final a = (1.0 - k);
      final r = d.baseR * (1.0 + 0.6 * k);

      _pDot.color = colOuter.withValues(alpha: 0.40 * a);
      c.drawCircle(Offset(d.pos.x, d.pos.y), r, _pDot);

      _pDot.color = Colors.white.withValues(alpha: 0.80 * a);
      c.drawCircle(Offset(d.pos.x, d.pos.y), r * 0.42, _pDot);
    }

    final r = headRadius;
    final speedDir = (_lastPos == null)
        ? (impactLocal - fromLocal).normalized()
        : (position - _lastPos!).normalized();

    // 头部拖影（更收敛）
    for (int i = 1; i <= 3; i++) {
      final k = i.toDouble();
      _pGlow.color = colOuter.withValues(alpha: 0.18 / k);
      final off = Offset(-speedDir.x * r * 0.6 * k, -speedDir.y * r * 0.6 * k);
      c.save();
      c.translate(off.dx, off.dy);
      c.drawCircle(Offset(position.x, position.y), r * (1.0 + 0.08 * k), _pGlow);
      c.restore();
    }

    // 头部核心：更亮、更实、更大（确保“头最大”）
    _pCore.shader = ui.Gradient.radial(
      Offset(position.x, position.y),
      r * (1.18 * coreBloom),
      [ Colors.white, colInner, colOuter.withValues(alpha: 0.90) ],
      const [ 0.0, 0.25, 1.0 ],
    );
    c.drawCircle(Offset(position.x, position.y), r * (1.10 * coreBloom), _pCore);

    // 额外小范围爆闪，进一步压住尾巴视觉
    final Paint flare = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10)
      ..color = Colors.white.withValues(alpha: 0.35);
    c.drawCircle(Offset(position.x, position.y), r * 0.65, flare);

    // 外层光晕
    _pGlow.color = colOuter.withValues(alpha: 0.28);
    c.drawCircle(Offset(position.x, position.y), r * glowBloom, _pGlow);
  }

  void _renderRibbon(Canvas c) {
    if (_backbone.length < 2) return;

    // 计算“尾部最大宽度”的绝对像素
    final double maxTailW = headRadius * tailMaxWidthRatio;

    for (int i = 0; i < _backbone.length - 1; i++) {
      final a = i / (_backbone.length - 1);
      final strength = pow(1.0 - a, tailAlphaPow).toDouble(); // ⬅️ 更快变暗
      double w = _lerp(streakWidth * 0.25, streakWidth, strength);

      // ⬅️ 硬性限制：尾巴宽度永远 ≤ 头
      w = w.clamp(headRadius * 0.18, maxTailW);

      // 模糊外焰（降低膨胀系数）
      _pRibbonBlur
        ..strokeWidth = w * tailBlurScale
        ..color = colOuter.withValues(alpha: 0.20 * strength);
      c.drawLine(
        Offset(_backbone[i].pos.x, _backbone[i].pos.y),
        Offset(_backbone[i + 1].pos.x, _backbone[i + 1].pos.y),
        _pRibbonBlur,
      );

      // 实体火焰带
      _pRibbon
        ..strokeWidth = w * 0.85
        ..color = colOuter.withValues(alpha: 0.50 * strength);
      c.drawLine(
        Offset(_backbone[i].pos.x, _backbone[i].pos.y),
        Offset(_backbone[i + 1].pos.x, _backbone[i + 1].pos.y),
        _pRibbon,
      );

      // 内核细亮芯
      _pRibbon
        ..strokeWidth = w * 0.32
        ..color = Colors.white.withValues(alpha: 0.70 * strength);
      c.drawLine(
        Offset(_backbone[i].pos.x, _backbone[i].pos.y),
        Offset(_backbone[i + 1].pos.x, _backbone[i + 1].pos.y),
        _pRibbon,
      );
    }
  }

  double _easeInCubic(double x) => x * x * x;
  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _Node {
  Vector2 pos;
  double width;
  double t;
  _Node({required this.pos, required this.width, required this.t});
}

class _Dot {
  final Vector2 pos;
  final double baseR;
  final double life;
  double t = 0.0;
  _Dot(this.pos, this.baseR, this.life);
}

/// 💥 真·爆炸（已有修复：不再“圆停住”，并带碎屑）
class MeteorExplosion extends PositionComponent {
  final Vector2 worldPos;
  final double  baseRadius;
  final Color   colInner;
  final Color   colOuter;
  final int     sparkCount;
  final int     debrisCount;
  final double  debrisMinSize;
  final double  debrisMaxSize;
  final int?    basePriority;

  MeteorExplosion({
    required this.worldPos,
    required this.baseRadius,
    required this.colInner,
    required this.colOuter,
    required this.sparkCount,
    required this.debrisCount,
    required this.debrisMinSize,
    required this.debrisMaxSize,
    this.basePriority,
  }) {
    anchor = Anchor.center;
    position = worldPos.clone();
    size = Vector2.all(baseRadius * 8);
  }

  final double flashLife = 0.08;
  final double ringLife  = 0.35;
  final double sparkLife = 0.42;
  final double debrisLife= 0.60;

  double _t = 0.0;
  final Random _rng = Random();

  late final List<_Spark> _sparks = List.generate(sparkCount, (_) {
    final ang = _rng.nextDouble() * pi * 2;
    final spd = _lerp(baseRadius * 6.0, baseRadius * 14.0, _rng.nextDouble());
    final v   = Vector2(cos(ang), sin(ang)) * spd;
    final life = _lerp(sparkLife * 0.55, sparkLife, _rng.nextDouble());
    return _Spark(pos: worldPos.clone(), vel: v, life: life);
  });

  late final List<_Debris> _debris = List.generate(debrisCount, (_) {
    final ang = _rng.nextDouble() * pi * 2;
    final spd = _lerp(baseRadius * 4.0, baseRadius * 10.0, _rng.nextDouble());
    final v   = Vector2(cos(ang), sin(ang)) * spd;

    final size = _lerp(debrisMinSize, debrisMaxSize, _rng.nextDouble());
    final spin = _lerp(-6.0, 6.0, _rng.nextDouble());
    final life = _lerp(debrisLife * 0.7, debrisLife, _rng.nextDouble());

    final colors = [
      const Color(0xFFE8B36A),
      const Color(0xFFD18E3B),
      const Color(0xFFEFC98A),
    ];
    final color = colors[_rng.nextInt(colors.length)];

    return _Debris(
      pos: worldPos.clone(),
      vel: v,
      size: size,
      angle: _rng.nextDouble() * pi,
      spin: spin,
      life: life,
      color: color,
    );
  });

  final Paint _pFlash = Paint()..blendMode = BlendMode.plus;
  final Paint _pRing  = Paint()
    ..blendMode = BlendMode.plus
    ..style = PaintingStyle.stroke
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18);
  final Paint _pSpark = Paint()
    ..blendMode = BlendMode.plus
    ..strokeCap = StrokeCap.round
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
  final Paint _pDebris = Paint()
    ..blendMode = BlendMode.srcOver
    ..isAntiAlias = true;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (basePriority != null) priority = basePriority!;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    for (final s in _sparks) {
      s.t += dt;
      final p = (s.t / s.life).clamp(0.0, 1.0);
      final drag = 1.0 - 0.85 * p;
      s.vel += Vector2(0, 800.0) * dt * 0.6;
      s.pos += s.vel * dt * drag;
    }
    _sparks.removeWhere((s) => s.t >= s.life);

    for (final d in _debris) {
      d.t += dt;
      final p = (d.t / d.life).clamp(0.0, 1.0);
      d.vel += Vector2(0, 900.0) * dt;
      d.pos += d.vel * dt * (1.0 - 0.4 * p);
      d.angle += d.spin * dt;
      d.size *= (1.0 - 0.15 * dt);
    }
    _debris.removeWhere((d) => d.t >= d.life);

    if (_t >= debrisLife && _sparks.isEmpty && _debris.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas c) {
    super.render(c);

    if (_t < flashLife) {
      final k = (_t / flashLife).clamp(0.0, 1.0);
      final a = 1.0 - k;
      _pFlash.shader = ui.Gradient.radial(
        Offset(worldPos.x, worldPos.y),
        baseRadius * 2.2,
        [
          Colors.white.withValues(alpha: 1.0 * a),
          colInner.withValues(alpha: 0.8 * a),
          colOuter.withValues(alpha: 0.0),
        ],
        const [0.0, 0.35, 1.0],
      );
      c.drawCircle(Offset(worldPos.x, worldPos.y), baseRadius * 1.6, _pFlash);
    }

    if (_t < ringLife) {
      final k = (_t / ringLife).clamp(0.0, 1.0);
      final ringR = baseRadius * _lerp(1.2, 6.0, k);
      _pRing
        ..strokeWidth = _lerp(8, 2, k)
        ..color = colOuter.withValues(alpha: _lerp(0.85, 0.0, k));
      c.drawCircle(Offset(worldPos.x, worldPos.y), ringR, _pRing);
    }

    for (final s in _sparks) {
      final p = (s.t / s.life).clamp(0.0, 1.0);
      final a = (1.0 - p);
      _pSpark
        ..color = colOuter.withValues(alpha: 0.80 * a)
        ..strokeWidth = _lerp(4.5, 1.3, p);
      final tail = Offset(-s.vel.x, -s.vel.y).scale(0.02, 0.02);
      c.drawLine(
        Offset(s.pos.x, s.pos.y),
        Offset(s.pos.x + tail.dx, s.pos.y + tail.dy),
        _pSpark,
      );
      c.drawCircle(Offset(s.pos.x, s.pos.y), 2.0, _pSpark);
    }

    for (final d in _debris) {
      final p = (d.t / d.life).clamp(0.0, 1.0);
      final a = (1.0 - p);
      _pDebris.color = d.color.withValues(alpha: 0.95 * a);

      c.save();
      c.translate(d.pos.x, d.pos.y);
      c.rotate(d.angle);

      final path = Path()
        ..moveTo(-d.size * 0.6, -d.size * 0.4)
        ..lineTo(d.size * 0.7, -d.size * 0.2)
        ..lineTo(d.size * 0.5, d.size * 0.6)
        ..lineTo(-d.size * 0.5, d.size * 0.3)
        ..close();

      c.drawPath(path, _pDebris);
      c.restore();
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _Spark {
  Vector2 pos;
  Vector2 vel;
  double  life;
  double  t = 0.0;
  _Spark({required this.pos, required this.vel, required this.life});
}

class _Debris {
  Vector2 pos;
  Vector2 vel;
  double  size;
  double  angle;
  double  spin;
  double  life;
  double  t = 0.0;
  final Color color;
  _Debris({
    required this.pos,
    required this.vel,
    required this.size,
    required this.angle,
    required this.spin,
    required this.life,
    required this.color,
  });
}
