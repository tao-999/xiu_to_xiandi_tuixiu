import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 挂在被命中的 mover 上的“被电到”覆盖特效
/// - 自动适配目标大小（onMount 读取父组件 size）
/// - 若目标移动，覆盖会跟随（作为其子组件）
/// - 渲染多条细分叉电弧 + 青白脉冲
class VfxElectroHitOverlay extends PositionComponent {
  final double life;            // 显示时长
  final int arcCount;           // 每帧电弧条数
  final int arcSegments;        // 每条电弧折线段数
  final double jitter;          // 抖动幅度（像素）
  final double thickness;       // 电弧线宽
  final Color color;            // 主色（建议偏蓝青）
  final double pulse;           // 呼吸脉冲强度 0~1
  final double shake;           // 轻微抖动像素（仅覆盖自身，不改怪位置）
  final int? basePriority;
  final int? seed;

  double _t = 0;
  late Random _rng;

  VfxElectroHitOverlay({
    this.life = 0.16,
    this.arcCount = 8,
    this.arcSegments = 7,
    this.jitter = 8,
    this.thickness = 1.6,
    this.color = const Color(0xFFB5F3FF),
    this.pulse = 0.65,
    this.shake = 0.8,
    this.basePriority,
    this.seed,
  }) {
    anchor = Anchor.center;
    _rng = Random(seed);
    if (basePriority != null) priority = basePriority!;
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    // 尺寸跟目标一致，略放大避免裁切
    final p = parent;
    if (p is PositionComponent) {
      size = p.size + Vector2.all(6);
      position = p.size / 2; // 局部中心
    } else {
      size = Vector2.all(32);
      position = Vector2.all(16);
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    // 时间进度 & 透明度
    final k = (_t / life).clamp(0.0, 1.0);
    final alpha = (1.0 - k); // 越到后期越淡
    if (alpha <= 0) return;

    // 轻微抖动（只抖覆盖，不动目标）
    final dx = (_rng.nextDouble() * 2 - 1) * shake;
    final dy = (_rng.nextDouble() * 2 - 1) * shake;
    canvas.translate(dx, dy);

    final rect = Offset.zero & Size(size.x, size.y);
    final center = rect.center;

    // 青白脉冲底光（plus 混合）
    final pulseA = (0.25 + 0.75 * (1 - k)) * pulse * alpha;
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..color = color.withOpacity(0.45 * pulseA)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      glow,
    );

    // 电弧笔刷
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..blendMode = BlendMode.plus
      ..color = color.withOpacity(0.95 * alpha);
    final glowLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 2.2
      ..blendMode = BlendMode.plus
      ..color = color.withOpacity(0.18 * alpha);

    // 多条电弧：起点多分布在边缘，终点向中心或另一边，带少量分叉
    for (int i = 0; i < arcCount; i++) {
      final path = Path();

      // 起点在外边界随机一点
      final side = _rng.nextInt(4);
      double x0, y0;
      switch (side) {
        case 0: // top
          x0 = _rng.nextDouble() * rect.width;
          y0 = 0;
          break;
        case 1: // right
          x0 = rect.width;
          y0 = _rng.nextDouble() * rect.height;
          break;
        case 2: // bottom
          x0 = _rng.nextDouble() * rect.width;
          y0 = rect.height;
          break;
        default: // left
          x0 = 0;
          y0 = _rng.nextDouble() * rect.height;
      }

      // 终点靠近中心（带偏移）
      final tgt = Offset(
        center.dx + (_rng.nextDouble() * 2 - 1) * rect.width * 0.18,
        center.dy + (_rng.nextDouble() * 2 - 1) * rect.height * 0.18,
      );

      // 折线细分
      final dx1 = tgt.dx - x0;
      final dy1 = tgt.dy - y0;
      final len = sqrt(dx1 * dx1 + dy1 * dy1);
      final dir = len == 0 ? const Offset(1, 0) : Offset(dx1 / len, dy1 / len);
      final nrm = Offset(-dir.dy, dir.dx);

      Offset p0 = Offset(x0, y0);
      path.moveTo(p0.dx, p0.dy);
      for (int s = 1; s <= arcSegments; s++) {
        final t = s / arcSegments;
        final along = len * t;
        final falloff = sin(pi * t); // 中段最大
        final off = (_rng.nextDouble() * 2 - 1) * jitter * falloff;
        final base = Offset(dir.dx * along, dir.dy * along);
        final jig  = Offset(nrm.dx * off, nrm.dy * off);
        final p = Offset(x0, y0) + base + jig;
        path.lineTo(p.dx, p.dy);

        // 小概率分叉
        if (_rng.nextDouble() < 0.18 && s > 1 && s < arcSegments) {
          final fork = Path()..moveTo(p.dx, p.dy);
          final forkLen = 8 + _rng.nextDouble() * 18;
          final sign = _rng.nextBool() ? 1 : -1;
          final fdir = Offset(nrm.dx * sign, nrm.dy * sign);
          final fp = p + Offset(fdir.dx * forkLen, fdir.dy * forkLen);
          fork.lineTo(fp.dx, fp.dy);
          canvas.drawPath(fork, glowLine);
          canvas.drawPath(fork, stroke);
        }

        p0 = p;
      }

      // 先发光、后描线
      canvas.drawPath(path, glowLine);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= life) removeFromParent();
  }
}
