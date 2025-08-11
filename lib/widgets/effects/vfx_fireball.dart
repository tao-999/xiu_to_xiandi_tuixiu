// 📄 lib/widgets/effects/vfx_fireball.dart
// 火球术 VFX（直飞/可转向追踪 + 中心命中判定 + 最大飞行距离）
//
// ✅ 逻辑：
// - 碰到 Boss 外圈 → 只“锁定目标”，继续飞向 Boss.center
// - 进入“中心半径”才结算伤害 + 爆闪
// - 有最大飞行距离 maxDistance：超过就到点爆散（不造成伤害）
// - 玩家是否能释放与射程无关（只看是否装备和冷却）

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;

import '../components/floating_island_dynamic_mover_component.dart';
import '../components/floating_island_player_component.dart';
import '../components/resource_bar.dart';

class FireballVfx extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  // ===== 外部参数 =====
  final Vector2 from;               // 父层本地（适配器已做绝对->本地）
  final Vector2 to;                 // 父层本地（直飞 fallback）
  final double speed;               // px/s
  final double radius;              // 可视半径
  final double trailFreq;           // 拖尾生成频率（次/秒）
  final double lifeAfterHit;        // 爆闪时长
  final PositionComponent? follow;  // 追踪目标（世界组件，可选）
  final double turnRateDegPerSec;   // >0 追踪；<=0 直飞
  final double? hitRadius;          // 锁定触发半径（外圈）
  final double damage;              // 入射伤害 = ATK * (1 + atkBoost)

  // ✅ 飞行距离限制（单位：px）
  final double maxDistance;         // 最大飞行距离
  final bool explodeOnTimeout;      // 距离耗尽是否播放爆散（不伤害）

  // ✅ 伤害结算上下文（统一走 applyDamage）
  final FloatingIslandPlayerComponent owner;
  final Vector2 Function() getLogicalOffset;
  final GlobalKey<ResourceBarState> resourceBarKey;

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
    this.turnRateDegPerSec = 0.0,   // 默认直飞
    this.hitRadius,
    required this.damage,
    required this.owner,
    required this.getLogicalOffset,
    required this.resourceBarKey,
    this.maxDistance = 360.0,       // ← 默认射程，按需覆盖
    this.explodeOnTimeout = true,   // ← 超程时播放小爆散
    this.destroyHitboxOnHit = true,
    int? priority,
  }) {
    anchor = Anchor.center;
    position = from.clone();
    size = Vector2.all(radius * 2);
    if (priority != null) this.priority = priority;
  }

  // ===== 内部状态 =====
  late Vector2 _vel;        // 速度向量（长度 = speed）
  double _trailAcc = 0;
  bool _exploding = false;
  double _explodeT = 0;
  late double _hitR;        // 锁定外圈半径
  bool _dealtDamage = false;
  CircleHitbox? _hitbox;

  // 🔒 被锁定、等待中心命中的 Boss
  FloatingIslandDynamicMoverComponent? _pendingBoss;
  bool _waitCenter = false;

  // 📏 飞行距离累计
  double _travel = 0.0;

  // 画笔缓存
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

    final tgt = _currentLocalTarget();
    final dir = (tgt - from);
    _vel = dir.length2 == 0 ? Vector2(1, 0) * speed : dir.normalized() * speed;
  }

  void triggerHit() {
    if (_exploding) return;
    _exploding = true;
    _explodeT = 0;
    if (destroyHitboxOnHit) {
      _hitbox?.removeFromParent();
      _hitbox = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_exploding) {
      _explodeT += dt;
      if (_explodeT >= lifeAfterHit) removeFromParent();
      return;
    }

    final tgt = _currentLocalTarget();
    final toTarget = tgt - position;
    final dist = toTarget.length;

    // 🌕 等待“中心命中”的流程
    if (_waitCenter && _pendingBoss != null && _pendingBoss!.isMounted) {
      final centerR = _centerExplodeRadius(_pendingBoss!);
      if (dist <= centerR) {
        _pendingBoss!.applyDamage(
          amount: damage,
          killer: owner,
          logicalOffset: getLogicalOffset(),
          resourceBarKey: resourceBarKey,
        );
        _dealtDamage = true;
        triggerHit();
        return;
      }
      // 引导速度朝向中心（即便最初为直飞）
      if (toTarget.length2 > 0) {
        final maxTurn = (max(turnRateDegPerSec, 720) * pi / 180.0) * dt;
        final ang = _angleBetween(_vel, toTarget);
        final clamped = ang.clamp(-maxTurn, maxTurn);
        _vel.rotate(clamped);
        _vel.setFrom(_vel.normalized() * speed);
      }
    } else {
      // 未锁定时不提前爆（统一走中心命中）
    }

    // ====== 位移 & 射程限制 ======
    final dirUnit = _vel.length2 == 0 ? Vector2(1, 0) : _vel.normalized();
    final stepLen = speed * dt;
    final remaining = max(0.0, maxDistance - _travel);
    final moveLen = min(stepLen, remaining);

    // 到点就地爆散（不伤害）
    if (moveLen <= 0.0) {
      if (explodeOnTimeout) triggerHit();
      else removeFromParent();
      return;
    }

    position += dirUnit * moveLen;
    _travel += moveLen;

    // 拖尾
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

  // ===== 碰撞回调：只做“锁定中心”，不在这里爆炸 =====
  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (_dealtDamage) return;

    if (other is! FloatingIslandDynamicMoverComponent) return;
    final t = other.type?.toLowerCase() ?? '';
    if (!t.contains('boss')) return;

    // ✅ 锁定目标，等待中心命中
    _pendingBoss = other;
    _waitCenter = true;

    // 后续不再触发碰撞；命中改由“中心判定”决定
    _hitbox?.collisionType = CollisionType.inactive;

    // 初次锁定时，把速度立即对准中心，避免绕圈
    final tgt = _currentLocalTarget();
    final dir = (tgt - position);
    if (dir.length2 > 0) {
      _vel = dir.normalized() * speed;
    }
  }

  // ===== 工具函数 =====
  Vector2 _currentLocalTarget() {
    // 优先瞄准“已锁定的 Boss”，否则按 follow/直飞 to
    final target = (_pendingBoss ?? follow);
    if (target != null && target.isMounted) {
      final world = target.absoluteCenter;
      final lp = _layerPC;
      if (lp != null) return lp.absoluteToLocal(world);
    }
    return to;
  }

  // 首次锁定用的“外圈”半径（较松）
  double _estimateLockRadius() {
    final target = (_pendingBoss ?? follow);
    if (target != null && target.isMounted) {
      final sz = target.size;
      return max(radius * 0.9, (sz.x + sz.y) * 0.25 + radius * 0.4);
    }
    return radius * 1.2;
  }

  // 真正爆炸的“中心命中半径”（较紧）
  double _centerExplodeRadius(FloatingIslandDynamicMoverComponent boss) {
    final avg = (boss.size.x + boss.size.y) * 0.25; // 近似半径
    return max(6.0, avg * 0.35);                    // 手感参数：越小越“贴脸”
  }

  double _angleBetween(Vector2 a, Vector2 b) {
    final na = a.normalized();
    final nb = b.normalized();
    final cross = na.cross(nb);
    final dot = na.dot(nb).clamp(-1.0, 1.0);
    return atan2(cross, dot);
  }

  void _drawBall(Canvas c, double r, double opacity) {
    // 1) 先铺一层“身体”——深橙填充，给颜色厚度（非叠加，避免被冲淡）
    final base = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.95 * opacity) // 深橙
      ..blendMode = BlendMode.srcOver;
    c.drawCircle(Offset.zero, r * 0.98, base);

    // 2) 中圈径向渐变：白热 → 柠黄 → 亮橙 → 暗橙红（更接近 emoji 火焰）
    final shader = ui.Gradient.radial(
      Offset.zero, r,
      [
        const Color(0xFFFFFFFF), // 核心白热
        const Color(0xFFFFF176), // 柠黄
        const Color(0xFFFFA000), // 亮橙
        const Color(0xFFE65100), // 暗橙红
      ],
      const [0.0, 0.25, 0.60, 1.0],
    );
    final mid = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    c.drawCircle(Offset.zero, r, mid);

    // 3) 热边亮环（让轮廓更“燥”）
    final hotRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.14).clamp(2.0, 5.0)
      ..blendMode = BlendMode.plus
      ..color = const Color(0xFFFFC107).withOpacity(0.90 * opacity);
    c.drawCircle(Offset.zero, r * 0.92, hotRing);

    // 4) 外圈暗红描边（类似 emoji 的黑/深边，但不完全黑以免脏）
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.18).clamp(2.0, 6.0)
      ..blendMode = BlendMode.srcOver
      ..color = const Color(0xFFBF360C).withOpacity(0.80 * opacity); // 暗红
    c.drawCircle(Offset.zero, r * 1.02, rim);

    // 5) 外部深红光晕（更浓）
    _glowPaint
      ..color = const Color(0xFFBF360C).withOpacity(0.85 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    c.drawCircle(Offset.zero, r * 1.55, _glowPaint);

    // 6) 中心白炽点稍大一点
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
