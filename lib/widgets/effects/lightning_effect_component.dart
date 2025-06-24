import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class LightningEffectComponent extends Component with HasGameReference {
  final Vector2 start;               // 起点位置（主角或屏幕外）
  final Vector2 direction;           // 方向（不再使用）
  double maxDistance;                // 最大射程（不再是final）
  final int lightningCount;          // 发射几道闪电

  final List<LightningBeam> _beamPool = [];

  final Paint _beamPaint = Paint()
    ..color = Colors.lightBlueAccent
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  LightningEffectComponent({
    required this.start,
    required this.direction,
    this.maxDistance = 160, // 默认最大射程
    this.lightningCount = 1,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    print('⚡ [闪电特效] 准备释放 $lightningCount 道闪电');

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

      // 计算目标和起点之间的实际距离作为最大射程
      maxDistance = (target.absolutePosition - start).length;

      final beam = _getBeamFromPool(start, target.absolutePosition, maxDistance);
      parent?.add(beam);

      await Future.delayed(const Duration(milliseconds: 10)); // 分帧发射
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
  double maxDistance;  // 最大射程
  final void Function(LightningBeam) onDispose;
  final Random _rng = Random();

  LightningBeam(this.from, this.to, this.beamPaint, {required this.maxDistance, required this.onDispose}) {
    priority = 1000;
    add(RemoveEffect(delay: 0.2, onComplete: () {
      onDispose(this);
      removeFromParent();
    }));
  }

  void reset(Vector2 newFrom, Vector2 newTo, double newMaxDistance) {
    from = newFrom;
    to = newTo;
    maxDistance = newMaxDistance;  // 更新最大射程
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final path = Path();
    path.moveTo(from.x, from.y);

    final segmentCount = 10;
    final direction = to - from;
    final segmentLength = direction.length / segmentCount;
    final segmentVector = direction.normalized() * segmentLength;

    // 让闪电多变，增加随机幅度
    for (int i = 1; i < segmentCount; i++) {
      final basePoint = from + segmentVector * i.toDouble();
      final offset = Vector2(
        (_rng.nextDouble() - 0.5) * 15,  // 水平±15像素随机偏移
        (_rng.nextDouble() - 0.5) * 15,  // 垂直±15像素随机偏移
      );
      final point = basePoint + offset;
      path.lineTo(point.x, point.y);
    }

    path.lineTo(to.x, to.y);

    // 绘制闪电路径
    canvas.drawPath(path, beamPaint);
  }
}
