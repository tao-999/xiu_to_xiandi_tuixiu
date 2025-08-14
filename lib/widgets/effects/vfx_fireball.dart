// 📄 lib/widgets/effects/vfx_fireball.dart
// 火球术 VFX —— 直飞/追踪 + 波形轨迹 + “进入 mover 区域即爆”(线段vsAABB) + 射程上限
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';

enum FireballRoute { straight, sine, wobble, arcLeft, arcRight }

class FireballVfx extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  // ===== 外部参数 =====
  final Vector2 from;               // 父层本地
  final Vector2 to;                 // 父层本地（直飞 fallback）
  final double speed;               // px/s
  final double radius;              // 可视半径
  final double trailFreq;           // 拖尾频率（次/秒）
  final double lifeAfterHit;        // 爆闪时长
  final PositionComponent? follow;  // 追踪目标（世界组件，可选）
  final double turnRateDegPerSec;   // >0 追踪；<=0 直飞
  final double? hitRadius;          // 触发半径（仅用于“首碰锁定”）
  final double damage;              // 入射伤害

  // ✅ 飞行距离限制
  final double maxDistance;
  final bool explodeOnTimeout;

  // ✅ 伤害结算上下文
  final FloatingIslandPlayerComponent owner;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

  // 轨迹参数
  final double initialAngleOffsetDeg; // 起飞偏角（扇形）
  final FireballRoute route;          // 路线类型
  final double routeAmpPx;            // 侧向幅度（像素）
  final double routeFreqHz;           // 频率（Hz）
  final double routePhase;            // 相位
  final double routeDecay;            // 幅度衰减（0~1）

  // 命中后移除 hitbox 防多次结算
  final bool destroyHitboxOnHit;

  FireballVfx({
    required this.from,
    required this.to,
    this.speed = 360.0,
    this.radius = 10.0,
    this.trailFreq = 40.0,
    this.lifeAfterHit = 0.18,
    this.follow,
    this.turnRateDegPerSec = 0.0,
    this.hitRadius,
    required this.damage,
    required this.owner,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    this.maxDistance = 360.0,
    this.explodeOnTimeout = true,
    this.destroyHitboxOnHit = true,
    int? priority,

    this.initialAngleOffsetDeg = 0.0,
    this.route = FireballRoute.straight,
    this.routeAmpPx = 0.0,
    this.routeFreqHz = 1.2,
    this.routePhase = 0.0,
    this.routeDecay = 0.9,
  }) {
    anchor = Anchor.center;
    position = from.clone();   // 可视+碰撞位置（父层本地）
    size = Vector2.all(radius * 2);
    if (priority != null) this.priority = priority;
  }

  // ===== 内部状态 =====
  late Vector2 _vel;            // 速度向量（长度 = speed）
  late Vector2 _corePos;        // 直线“核心点”，视觉=核心+侧向
  late Vector2 _prevPos;        // 上一帧“视觉位置”（做线段检测）
  double _trailAcc = 0;
  bool _exploding = false;
  double _explodeT = 0;
  late double _hitR;
  bool _dealtDamage = false;
  CircleHitbox? _hitbox;

  FloatingIslandDynamicMoverComponent? _lockedMover; // 首次碰撞后锁定
  bool _waitCenter = false;                          // 进入区域才爆（不再用点半径）

  double _travel = 0.0;     // 直线位移累计
  double _t = 0.0;          // 累计时间（波形用）

  final Paint _glowPaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _corePaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Random _rng = Random();

  PositionComponent? get _layerPC =>
      parent is PositionComponent ? parent as PositionComponent : null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitR = hitRadius ?? _estimateLockRadius();

    _hitbox = CircleHitbox(radius: _hitR)
      ..collisionType = CollisionType.active
      ..anchor = Anchor.center;
    add(_hitbox!);

    _corePos = from.clone();
    _prevPos = position.clone();

    final tgt = _currentLocalTarget();
    final dir = (tgt - from);
    _vel = dir.length2 == 0 ? Vector2(1, 0) * speed : dir.normalized() * speed;

    // 起飞角度偏转（扇形展开）
    final ang = initialAngleOffsetDeg * pi / 180.0;
    if (ang.abs() > 1e-6) {
      _vel.rotate(ang);
    }
  }

  void triggerHit() {
    if (_exploding) return;
    _exploding = true;
    _explodeT = 0;
    _vel.setZero(); // 命中后立刻停下，进入爆闪
    if (destroyHitboxOnHit) {
      _hitbox?.removeFromParent();
      _hitbox = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 目标在途中被移除/卸载 → 立刻处理
    if (_waitCenter && (_lockedMover == null || !_lockedMover!.isMounted)) {
      if (explodeOnTimeout) triggerHit();
      else removeFromParent();
    }

    if (_exploding) {
      _explodeT += dt;
      if (_explodeT >= lifeAfterHit) removeFromParent();
      return;
    }

    _t += dt;

    // 追踪/锁定：用视觉位置判断方向
    final tgt = _currentLocalTarget();
    final toTargetVisual = tgt - position;

    if (_waitCenter && _lockedMover != null && _lockedMover!.isMounted) {
      // 强制最低转向，确保能拐进目标
      if (toTargetVisual.length2 > 0) {
        final turnDeg = max(turnRateDegPerSec, 720);
        final maxTurn = (turnDeg * pi / 180.0) * dt;
        final ang = _angleBetween(_vel, toTargetVisual);
        final clamped = ang.clamp(-maxTurn, maxTurn);
        _vel.rotate(clamped);
        _vel.setFrom(_vel.normalized() * speed);
      }
    } else {
      // 常规追踪（可选）
      if (follow != null && turnRateDegPerSec > 0 && toTargetVisual.length2 > 0) {
        final maxTurn = (turnRateDegPerSec * pi / 180.0) * dt;
        final ang = _angleBetween(_vel, toTargetVisual);
        final clamped = ang.clamp(-maxTurn, maxTurn);
        _vel.rotate(clamped);
        _vel.setFrom(_vel.normalized() * speed);
      }
    }

    // ====== 位移（移动 _corePos，视觉=核心+侧向） ======
    final dirUnit = _vel.length2 == 0 ? Vector2(1, 0) : _vel.normalized();
    final stepLen = speed * dt;
    final remaining = max(0.0, maxDistance - _travel);
    final moveLen = min(stepLen, remaining);

    if (moveLen <= 0.0) {
      if (explodeOnTimeout) triggerHit();
      else removeFromParent();
      return;
    }

    _corePos += dirUnit * moveLen;
    _travel += moveLen;

    // —— 计算视觉位置
    _prevPos.setFrom(position); // 记录上一帧视觉位置
    position = _corePos + _lateralOffset(dirUnit);

    // ====== 🧱 “进入就爆” —— 线段 vs 扩展AABB 检测 ======
    if (_waitCenter && _lockedMover != null && _lockedMover!.isMounted) {
      final Rect aabb = _moverAabbLocal(_lockedMover!);
      if (_segmentIntersectsAabb(_prevPos, position, _expandRect(aabb, radius))) {
        // 命中（进入 mover 范围）
        if (!_dealtDamage) {
          _lockedMover!.applyDamage(
            amount: damage,
            killer: owner,
            logicalOffset: getLogicalOffset(),
            resourceBarKey: resourceBarKey,
          );
          _dealtDamage = true;
        }
        triggerHit();
        return;
      }
    }

    _emitTrail(dt);
  }

  // 拖尾
  void _emitTrail(double dt) {
    _trailAcc += dt * trailFreq;
    while (_trailAcc >= 1) {
      _trailAcc -= 1;
      parent?.add(_FireballTrailDot(
        worldPos: position + Vector2(
          (_rng.nextDouble() - 0.5) * radius * 0.3,
          (_rng.nextDouble() - 0.5) * radius * 0.3,
        ),
        baseR: radius * (0.55 + _rng.nextDouble() * 0.25),
        life: 0.22 + _rng.nextDouble() * 0.1,
      )..priority = (priority ?? 0) + 1);
    }
  }

  // ===== 碰撞回调：只做“锁定”，不在这里爆炸 =====
  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);

    // 已锁定/已结算就忽略，防止“换目标”
    if (_waitCenter || _dealtDamage) return;
    if (other is! FloatingIslandDynamicMoverComponent) return;

    _lockedMover = other;
    _waitCenter = true;

    // 彻底移除自身 hitbox，杜绝后续 onCollision
    _hitbox?.removeFromParent();
    _hitbox = null;

    // 初次锁定时，把速度对准中心
    final tgt = _absToLocal(other.absoluteCenter);
    final dir = (tgt - position);
    if (dir.length2 > 0) {
      _vel = dir.normalized() * speed;
    }
  }

  // ===== 轨迹：法向侧向位移 =====
  Vector2 _lateralOffset(Vector2 dirUnit) {
    if (route == FireballRoute.straight || routeAmpPx.abs() < 1e-3) {
      return Vector2.zero();
    }
    final n = Vector2(-dirUnit.y, dirUnit.x); // 左手法向
    final prog = (_travel / max(1e-6, maxDistance)).clamp(0.0, 1.0);
    final amp = routeAmpPx * pow(routeDecay.clamp(0.0, 1.0), prog * 1.0);

    double k = 0.0;
    switch (route) {
      case FireballRoute.sine:
        k = sin(2 * pi * routeFreqHz * _t + routePhase);
        break;
      case FireballRoute.wobble:
        k = 0.7 * sin(2 * pi * routeFreqHz * _t + routePhase)
            + 0.3 * sin(4 * pi * routeFreqHz * _t + routePhase * 1.7);
        break;
      case FireballRoute.arcLeft:
      case FireballRoute.arcRight:
        final s = math.sin(prog * math.pi * 0.9);
        final dir = (route == FireballRoute.arcLeft) ? 1.0 : -1.0;
        k = dir * s;
        break;
      case FireballRoute.straight:
        k = 0.0;
    }
    return n * (amp * k);
  }

  // ===== 工具函数 =====
  Vector2 _currentLocalTarget() {
    final target = (_lockedMover ?? follow);
    if (target != null && target.isMounted) {
      return _absToLocal(target.absoluteCenter);
    }
    return to;
  }

  Vector2 _absToLocal(Vector2 world) {
    final lp = _layerPC;
    if (lp != null) return lp.absoluteToLocal(world);
    return world;
  }

  Rect _moverAabbLocal(FloatingIslandDynamicMoverComponent m) {
    // 假设 mover.anchor = center（你的 mover 默认就是 center）
    final c = _absToLocal(m.absoluteCenter);
    final half = m.size / 2;
    return Rect.fromLTWH(c.x - half.x, c.y - half.y, m.size.x, m.size.y);
  }

  Rect _expandRect(Rect r, double pad) =>
      Rect.fromLTWH(r.left - pad, r.top - pad, r.width + pad * 2, r.height + pad * 2);

  // 线段 [p0,p1] 与 AABB 相交（slab 法），AABB 已按子弹半径外扩
  bool _segmentIntersectsAabb(Vector2 p0, Vector2 p1, Rect aabb) {
    final dx = p1.x - p0.x;
    final dy = p1.y - p0.y;

    double tMin = 0.0, tMax = 1.0;

    bool update(double p, double q) {
      if (p == 0) return q >= 0;        // 平行且在范围内
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

    // x 轴裁剪
    if (!update(-dx, p0.x - aabb.left)) return false;
    if (!update( dx, aabb.right - p0.x)) return false;

    // y 轴裁剪
    if (!update(-dy, p0.y - aabb.top)) return false;
    if (!update( dy, aabb.bottom - p0.y)) return false;

    return tMax >= tMin; // 有重叠区间 → 相交
  }

  double _estimateLockRadius() {
    final target = (_lockedMover ?? follow);
    if (target != null && target.isMounted) {
      final sz = target.size;
      return max(radius * 0.9, (sz.x + sz.y) * 0.25 + radius * 0.4);
    }
    return radius * 1.2;
  }

  double _angleBetween(Vector2 a, Vector2 b) {
    final na = a.normalized();
    final nb = b.normalized();
    final cross = na.cross(nb);
    final dot = na.dot(nb).clamp(-1.0, 1.0);
    return atan2(cross, dot);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_exploding) {
      final t = (_explodeT / lifeAfterHit).clamp(0.0, 1.0);
      final r = radius * (1.8 + 1.2 * t);
      final a = (1.0 - t);
      _drawBall(canvas, r, a);
      return;
    }

    _drawBall(canvas, radius, 1.0);
  }

  void _drawBall(Canvas c, double r, double opacity) {
    final base = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.95 * opacity)
      ..blendMode = BlendMode.srcOver;
    c.drawCircle(Offset.zero, r * 0.98, base);

    final shader = ui.Gradient.radial(
      Offset.zero, r,
      [
        const Color(0xFFFFFFFF),
        const Color(0xFFFFF176),
        const Color(0xFFFFA000),
        const Color(0xFFE65100),
      ],
      const [0.0, 0.25, 0.60, 1.0],
    );
    final mid = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    c.drawCircle(Offset.zero, r, mid);

    final hotRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.14).clamp(2.0, 5.0)
      ..blendMode = BlendMode.plus
      ..color = const Color(0xFFFFC107).withOpacity(0.90 * opacity);
    c.drawCircle(Offset.zero, r * 0.92, hotRing);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.18).clamp(2.0, 6.0)
      ..blendMode = BlendMode.srcOver
      ..color = const Color(0xFFBF360C).withOpacity(0.80 * opacity);
    c.drawCircle(Offset.zero, r * 1.02, rim);

    _glowPaint
      ..color = const Color(0xFFBF360C).withOpacity(0.85 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    c.drawCircle(Offset.zero, r * 1.55, _glowPaint);

    _corePaint.color = Colors.white.withOpacity(1.0 * opacity);
    c.drawCircle(Offset.zero, r * 0.50, _corePaint);
  }
}

// 🔸 拖尾小光点
class _FireballTrailDot extends PositionComponent {
  final Vector2 worldPos;
  final double baseR;
  final double life;
  double _t = 0;

  final Paint _p = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  _FireballTrailDot({
    required this.worldPos,
    required this.baseR,
    required this.life,
  }) {
    anchor = Anchor.center;
    position = worldPos.clone();
    size = Vector2.all(baseR * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= life) {
      removeFromParent();
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final k = (_t / life).clamp(0.0, 1.0);
    final r = baseR * (1.0 + 0.6 * k);
    final a = 0.55 * (1.0 - k);
    _p.color = const Color(0xFFFFB300).withOpacity(a);
    canvas.drawCircle(Offset.zero, r, _p);
  }
}
