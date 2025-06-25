import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class LightningEffectComponent extends Component with HasGameReference {
  final Vector2 start;
  final Vector2 direction;
  double maxDistance;
  final int lightningCount;

  final List<LightningBeam> _beamPool = [];

  final Paint _beamPaint = Paint()
    ..color = Colors.white // ✅ 改成白色
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  LightningEffectComponent({
    required this.start,
    required this.direction,
    this.maxDistance = 160,
    this.lightningCount = 1,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final targets = parent?.children.whereType<PositionComponent>().where((c) {
      final delta = c.absolutePosition - start;
      final dist = delta.length;
      final isValid = dist <= maxDistance && c != this;
      return isValid;
    }).toList() ?? [];

    targets.shuffle();
    final maxCount = lightningCount.clamp(1, 20);

    for (int i = 0; i < min(maxCount, targets.length); i++) {
      final target = targets[i];
      maxDistance = (target.absolutePosition - start).length;

      final beam = _getBeamFromPool(start, target.absolutePosition, maxDistance);
      parent?.add(beam);

      await Future.delayed(const Duration(milliseconds: 10));
    }

    add(RemoveEffect(delay: 0.25));
  }

  LightningBeam _getBeamFromPool(Vector2 from, Vector2 to, double maxDistance) {
    LightningBeam beam;
    if (_beamPool.isNotEmpty) {
      beam = _beamPool.removeLast();
      beam.reset(from, to, maxDistance);
    } else {
      beam = LightningBeam(from, to, _beamPaint, maxDistance: maxDistance, onDispose: _returnBeamToPool);
    }
    return beam;
  }

  void _returnBeamToPool(LightningBeam beam) {
    if (!_beamPool.contains(beam)) {
      _beamPool.add(beam);
    }
  }
}

class LightningBeam extends ShapeComponent {
  Vector2 from;
  Vector2 to;
  final Paint beamPaint;
  double maxDistance;
  final void Function(LightningBeam) onDispose;
  final Random _rng = Random();

  LightningBeam(this.from, this.to, this.beamPaint, {
    required this.maxDistance,
    required this.onDispose,
  }) {
    priority = 1000;
    add(RemoveEffect(
      delay: 0.25,
      onComplete: () {
        onDispose(this);
        removeFromParent();
      },
    ));
  }

  void reset(Vector2 newFrom, Vector2 newTo, double newMaxDistance) {
    from = newFrom;
    to = newTo;
    maxDistance = newMaxDistance;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final path = Path();
    final segmentCount = 12;
    final direction = to - from;
    final segmentLength = direction.length / segmentCount;
    final segmentVector = direction.normalized() * segmentLength;

    final points = <Offset>[];
    path.moveTo(from.x, from.y);
    points.add(from.toOffset());

    // 主干锯齿路径
    for (int i = 1; i < segmentCount; i++) {
      final base = from + segmentVector * i.toDouble();
      final offset = Vector2(
        (_rng.nextDouble() - 0.5) * 30, // 大震荡感
        (_rng.nextDouble() - 0.5) * 30,
      );
      final point = base + offset;
      path.lineTo(point.x, point.y);
      points.add(point.toOffset());
    }

    path.lineTo(to.x, to.y);
    points.add(to.toOffset());

    // ⚡ 发光边框效果（先画 Glow）
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);

    // ⚡ 主体白雷
    canvas.drawPath(path, beamPaint);

    // ✅ 分叉：从中间几段劈出 1~3 个一层分支（不再是固定数量）
    final forkCount = _rng.nextInt(3) + 1;
    for (int i = 3; i < segmentCount - 3 && forkCount > 0; i++) {
      if (_rng.nextBool()) {
        final base = from + segmentVector * i.toDouble();
        _drawFork(canvas, base, 1); // 一级分支
        if (_rng.nextBool()) _drawFork(canvas, base, 2); // 可选二级分支
      }
    }
  }

  void _drawFork(Canvas canvas, Vector2 from, int level) {
    final length = 30.0 / level + _rng.nextDouble() * 20;
    final angle = _rng.nextDouble() * pi * 2;
    final forkDir = Vector2(cos(angle), sin(angle));
    final to = from + forkDir * length;

    final forkPath = Path()
      ..moveTo(from.x, from.y)
      ..lineTo(to.x, to.y);

    final forkPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(forkPath, forkPaint);
  }
}
