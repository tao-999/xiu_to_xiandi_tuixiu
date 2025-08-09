// 📂 lib/widgets/effects/vfx_airflow.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

enum ColorMixMode { solid, linear, hsv }
enum MoveDir { idle, up, down, left, right, upLeft, upRight, downLeft, downRight }

MoveDir detectMoveDir(Vector2 v, {double deadZone = 1e-3}) {
  if (v.length2 < deadZone * deadZone) return MoveDir.idle;
  final dx = v.x, dy = v.y;
  if (dx.abs() < dy.abs() * 0.4142) return dy < 0 ? MoveDir.up : MoveDir.down;
  if (dy.abs() < dx.abs() * 0.4142) return dx < 0 ? MoveDir.left : MoveDir.right;
  if (dx < 0 && dy < 0) return MoveDir.upLeft;
  if (dx > 0 && dy < 0) return MoveDir.upRight;
  if (dx < 0 && dy > 0) return MoveDir.downLeft;
  return MoveDir.downRight;
}

/// ✅ 周身气流（世界坐标基准，支持挂到 parent）+ 圆弧可视化调试
class AirFlowEffect extends PositionComponent {
  // —— 宿主信息（必须提供） —— //
  final Vector2 Function() getWorldCenter; // 宿主世界“基准点”（见 centerYFactor 注释）
  final Vector2 Function() getHostSize;    // 宿主当前尺寸（用于半径/纵向偏移）

  // —— 驱动量 —— //
  Vector2 moveVector = Vector2.zero();     // 世界移动向量
  bool enabled = true;

  // —— 颜色配置 —— //
  List<Color> palette;
  final ColorMixMode mixMode;
  final bool gradientOnCore;
  final bool gradientOnGlow;
  final bool gradientOnSmoke;

  // —— 发射强度 —— //
  double baseRate;
  double ringRadius;
  double speedBoostMul;

  // ======= 🔧 校准参数 ======= //
  /// 圆心 = getWorldCenter() - (0, host.h * centerYFactor)
  /// 注意：若 getWorldCenter() 传“脚底”，这里就用 0.60~0.66；若传“中心”，这里建议 0.15~0.22。
  double centerYFactor;

  /// 半径估计：min(host.w, host.h) * radiusFactor
  double radiusFactor;

  /// 反方向 ±arcHalfAngle 的随机抖动（可见圆弧的半角）
  double arcHalfAngle;

  /// 起点沿外法线再外推（像素）
  double pad;

  /// 左右不对称修正（按“反方向的世界 X”判断）
  double biasLeftX;
  double biasRightX;

  // —— 调试可视化（圆弧） —— //
  bool showDebugArc;
  Color debugArcColor;
  double debugArcWidth;
  int debugArcSamples;

  // —— 内部 —— //
  final Random _rng = Random();
  double _emitTicker = 0;
  double _linger = 0;

  AirFlowEffect({
    required this.getWorldCenter,
    required this.getHostSize,
    this.palette = const [],
    this.mixMode = ColorMixMode.linear,
    this.gradientOnCore = true,
    this.gradientOnGlow = true,
    this.gradientOnSmoke = false,
    this.baseRate = 160,
    this.ringRadius = 12,
    this.speedBoostMul = 1.6,
    this.centerYFactor = 0.62,
    this.radiusFactor = 0.48,
    this.arcHalfAngle = pi / 12, // ≈15°
    this.pad = 1.8,
    this.biasLeftX = 0.0,
    this.biasRightX = 0.0,
    // 可视化
    this.showDebugArc = false,
    this.debugArcColor = const Color(0xFFFF00FF),
    this.debugArcWidth = 1.5,
    this.debugArcSamples = 32,
  }) : super(priority: 999, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 给调试看得见一个小框；位置每帧同步，所以会贴着宿主
    size = Vector2.all(ringRadius * 2 + 2);
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // —— 同步自身位置到“父系局部”的宿主世界中心 —— //
    final wc = getWorldCenter(); // 世界坐标
    if (parent is PositionComponent) {
      position = (parent as PositionComponent).absoluteToLocal(wc);
    } else {
      position = wc; // 兜底
    }

    final v = moveVector.clone();
    final speed = v.length;
    final moving = speed > 1e-2 && enabled;

    _linger = (moving ? _linger + dt * 2.6 : _linger - dt * 1.25).clamp(0.0, 1.0);
    if (_linger <= 1e-3) return;

    final rateMul = 1.0 + (speed / 180.0).clamp(0.0, speedBoostMul - 1.0);
    final emitPerSec = baseRate * rateMul * _linger;

    _emitTicker += dt * emitPerSec;
    while (_emitTicker >= 1) {
      _emitTicker -= 1;
      _emitOnce(v);
    }
  }

  void _emitOnce(Vector2 moveV) {
    var v = moveV.clone();
    if (v.length2 < 1e-8) return;
    v.normalize();

    // —— 世界反方向 —— //
    final Vector2 backWorld = -v;

    // —— 世界几何：圆心/半径/方向角 —— //
    final hostSize = getHostSize();
    final centerWorld = getWorldCenter() - Vector2(0, hostSize.y * centerYFactor);
    final double r = min(hostSize.x, hostSize.y) * radiusFactor;

    final double backAngle = atan2(backWorld.y, backWorld.x);
    final double jitter = (_rng.nextDouble() * 2 - 1) * arcHalfAngle;
    final double theta = backAngle + jitter;

    // 世界起点（圆弧边缘）
    Vector2 originWorld = centerWorld + Vector2(cos(theta), sin(theta)) * (r + pad);

    // 左右偏置（世界 X 判定）
    final bool backIsRight = backWorld.x > 0;
    originWorld += Vector2(backIsRight ? biasRightX : biasLeftX, 0);

    // —— 世界 → 本地（以特效组件为参照） —— //
    final spawnLocal = _worldToThisLocal(originWorld);

    // —— 发射参数 —— //
    final speed = moveV.length;
    final baseSpread = 0.45;
    final spread = (baseSpread - (speed.clamp(0, 240) / 240) * 0.22).clamp(0.18, 0.45);
    final jitter2 = (_rng.nextDouble() * 2 - 1) * spread;
    final dirVec = backWorld.clone()..rotate(jitter2);

    final spd  = 220 + _rng.nextDouble() * 160 + speed * 0.6;
    final life = 0.18 + _rng.nextDouble() * 0.12 + speed / 900.0;
    final vel  = dirVec * spd;
    final ang  = atan2(vel.y, vel.x);

    final c1 = _pickColor();
    final c2 = _pickColor(exclude: c1);
    final coreStart = _mixColor(c1, c2, 0.15);
    final coreEnd   = _mixColor(c1, c2, 0.45);
    final glowA     = _mixColor(c1, c2, 0.3);
    final glowB     = _mixColor(c1, c2, 0.7);
    final smokeC    = _mixColor(c1, c2, 0.5);

    // 1) 核心
    add(ParticleSystemComponent(
      particle: AcceleratedParticle(
        lifespan: life * 0.85,
        acceleration: -vel * 0.65,
        speed: vel,
        child: gradientOnCore && mixMode != ColorMixMode.solid
            ? _plumeCoreGradient(
          start: coreStart, end: coreEnd,
          thickness: 2.0 + _rng.nextDouble() * 1.6,
          angle: ang, lenMul: 1.2 + speed / 260.0,
        )
            : _plumeCoreSolid(
          color: coreStart,
          thickness: 2.0 + _rng.nextDouble() * 1.6,
          angle: ang, lenMul: 1.2 + speed / 260.0,
        ),
      ),
      position: spawnLocal,
    ));

    // 2) 光晕
    add(ParticleSystemComponent(
      particle: AcceleratedParticle(
        lifespan: life,
        acceleration: -vel * 0.55,
        speed: vel,
        child: gradientOnGlow && mixMode != ColorMixMode.solid
            ? _plumeGlowGradient(a: glowA, b: glowB)
            : _plumeGlowSolid(color: glowA),
      ),
      position: spawnLocal,
    ));

    // 3) 烟羽
    if (_rng.nextDouble() < 0.6) {
      final smokeVel = vel * (0.55 + _rng.nextDouble() * 0.25);
      add(ParticleSystemComponent(
        particle: AcceleratedParticle(
          lifespan: life * (1.1 + _rng.nextDouble() * 0.4),
          acceleration: -smokeVel * 0.35,
          speed: smokeVel,
          child: gradientOnSmoke && mixMode != ColorMixMode.solid
              ? _smokePuffGradient(
            start: _withAlpha(smokeC, 0.22),
            end: _withAlpha(smokeC, 0.03),
            rStart: 6 + _rng.nextDouble() * 4,
            rEnd: 16 + _rng.nextDouble() * 10,
          )
              : _smokePuffSolid(
            color: _withAlpha(smokeC, 0.22),
            rStart: 6 + _rng.nextDouble() * 4,
            rEnd: 16 + _rng.nextDouble() * 10,
          ),
        ),
        position: spawnLocal,
      ));
    }
  }

  // ---------- 圆弧可视化（调试） ----------
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!showDebugArc) return;

    // 计算世界几何
    final hostSize = getHostSize();
    final centerWorld = getWorldCenter() - Vector2(0, hostSize.y * centerYFactor);
    final r = min(hostSize.x, hostSize.y) * radiusFactor;

    final v = moveVector.clone();
    if (v.length2 < 1e-12) return;
    v.normalize();
    final backWorld = -v;
    final backAngle = atan2(backWorld.y, backWorld.x);

    final thetaMin = backAngle - arcHalfAngle;
    final thetaMax = backAngle + arcHalfAngle;

    // 转到本地
    final centerLocal = _worldToThisLocal(centerWorld);

    // 画中心点
    final pCenter = Paint()
      ..color = debugArcColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerLocal.x, centerLocal.y), 2.0, pCenter);

    // 画反向指示线
    final line = Paint()
      ..color = debugArcColor
      ..strokeWidth = debugArcWidth;
    final dirEnd = centerLocal + Vector2(cos(backAngle), sin(backAngle)) * r;
    canvas.drawLine(
      Offset(centerLocal.x, centerLocal.y),
      Offset(dirEnd.x, dirEnd.y),
      line,
    );

    // 画圆弧（采样点）
    final path = Path();
    Vector2 first = Vector2(
      centerLocal.x + cos(thetaMin) * r,
      centerLocal.y + sin(thetaMin) * r,
    );
    path.moveTo(first.x, first.y);

    final steps = max(8, debugArcSamples);
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final th = thetaMin + (thetaMax - thetaMin) * t;
      final px = centerLocal.x + cos(th) * r;
      final py = centerLocal.y + sin(th) * r;
      path.lineTo(px, py);
    }
    final pArc = Paint()
      ..color = debugArcColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = debugArcWidth;
    canvas.drawPath(path, pArc);

    // 画起点外推 pad 边界（可选）
    final pPad = Paint()
      ..color = debugArcColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      Offset(centerLocal.x, centerLocal.y),
      r + pad,
      pPad,
    );
  }

  // ---------------- 工具 & 渲染器 ----------------

  // 世界点 → 本地（以特效组件为参照）
  // vfx_airflow.dart 内
// ✅ 用组件自己的变换链，自动考虑 anchor/scale/父级等
  Vector2 _worldToThisLocal(Vector2 worldPoint) {
    return absoluteToLocal(worldPoint);
  }

  Particle _plumeCoreSolid({
    required Color color,
    required double thickness,
    required double angle,
    required double lenMul,
  }) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final p = Paint()
          ..blendMode = BlendMode.plus
          ..color = color.withOpacity(0.95 * (1 - t))
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
        final len = 16.0 * lenMul * (1.0 - 0.35 * t);
        canvas.save();
        canvas.rotate(angle);
        canvas.drawLine(Offset(-len * 0.15, 0), Offset(len, 0), p);
        canvas.restore();
      },
    );
  }

  Particle _plumeCoreGradient({
    required Color start,
    required Color end,
    required double thickness,
    required double angle,
    required double lenMul,
  }) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final len = 16.0 * lenMul * (1.0 - 0.35 * t);
        final a = 0.95 * (1 - t);

        final c0 = (mixMode == ColorMixMode.hsv) ? _hsvLerp(start, end, 0.0) : start;
        final c1 = (mixMode == ColorMixMode.hsv) ? _hsvLerp(start, end, 1.0) : end;

        final shader = ui.Gradient.linear(
          Offset(-len * 0.15, 0),
          Offset(len, 0),
          [c0.withOpacity(a), c1.withOpacity(a * 0.8)],
        );
        final p = Paint()
          ..blendMode = BlendMode.plus
          ..shader = shader
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
        canvas.save();
        canvas.rotate(angle);
        canvas.drawLine(Offset(-len * 0.15, 0), Offset(len, 0), p);
        canvas.restore();
      },
    );
  }

  Particle _plumeGlowSolid({required Color color}) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final paint = Paint()
          ..blendMode = BlendMode.plus
          ..color = color.withOpacity(0.55 * (1 - t))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final r = 4.0 * (1.0 + 0.8 * (1 - t));
        canvas.drawCircle(Offset.zero, r, paint);
      },
    );
  }

  Particle _plumeGlowGradient({required Color a, required Color b}) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final c0 = (mixMode == ColorMixMode.hsv) ? _hsvLerp(a, b, 0.0) : a;
        final c1 = (mixMode == ColorMixMode.hsv) ? _hsvLerp(a, b, 1.0) : b;

        final r = 4.0 * (1.0 + 0.8 * (1 - t));
        final shader = ui.Gradient.radial(
          Offset.zero, r,
          [c0.withOpacity(0.55 * (1 - t)), c1.withOpacity(0.0)],
          [0.0, 1.0],
        );
        final paint = Paint()
          ..blendMode = BlendMode.plus
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, r, paint);
      },
    );
  }

  Particle _smokePuffSolid({
    required Color color,
    required double rStart,
    required double rEnd,
  }) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final r = rStart + (rEnd - rStart) * t;
        final paint = Paint()
          ..color = color.withOpacity((color.opacity) * (1.0 - t))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(Offset.zero, r, paint);
      },
    );
  }

  Particle _smokePuffGradient({
    required Color start,
    required Color end,
    required double rStart,
    required double rEnd,
  }) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final t = particle.progress;
        final r = rStart + (rEnd - rStart) * t;
        final a = (mixMode == ColorMixMode.hsv) ? _hsvLerp(start, end, t) : _lerpColor(start, end, t);
        final shader = ui.Gradient.radial(
          Offset.zero, r,
          [a, end.withOpacity(0)],
          [0.0, 1.0],
        );
        final paint = Paint()
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(Offset.zero, r, paint);
      },
    );
  }

  // ---------------- 颜色工具 ----------------

  Color _pickColor({Color? exclude}) {
    final base = (palette.isEmpty)
        ? <Color>[
      const Color(0xFFFFF2B3),
      const Color(0xFFFFD180),
      const Color(0xFFFFAB91),
      const Color(0xFFFFE082),
    ]
        : palette;
    if (base.length == 1) return base.first;
    Color c;
    do { c = base[_rng.nextInt(base.length)]; }
    while (exclude != null && base.length > 1 && c == exclude);
    return c;
  }

  Color _lerpColor(Color a, Color b, double t) {
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * t).round(),
      (a.red   + (b.red   - a.red)   * t).round(),
      (a.green + (b.green - a.green) * t).round(),
      (a.blue  + (b.blue  - a.blue)  * t).round(),
    );
  }

  Color _hsvLerp(Color a, Color b, double t) {
    final ah = HSVColor.fromColor(a);
    final bh = HSVColor.fromColor(b);
    double dh = ((bh.hue - ah.hue + 540) % 360) - 180; // 最近路径
    final hue = (ah.hue + dh * t + 360) % 360;
    final sat = ah.saturation + (bh.saturation - ah.saturation) * t;
    final val = ah.value + (bh.value - ah.value) * t;
    final alp = a.opacity + (b.opacity - a.opacity) * t;
    return HSVColor.fromAHSV(alp, hue, sat, val).toColor();
  }

  Color _mixColor(Color a, Color b, double t) {
    switch (mixMode) {
      case ColorMixMode.solid: return a;
      case ColorMixMode.linear: return _lerpColor(a, b, t);
      case ColorMixMode.hsv: return _hsvLerp(a, b, t);
    }
  }

  Color _withAlpha(Color c, double a) => c.withOpacity(a);
}
