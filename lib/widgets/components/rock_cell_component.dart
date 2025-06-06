import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'pickaxe_effect_component.dart';
import 'chiyangu_game.dart';

class RockCellComponent extends PositionComponent
    with TapCallbacks, HasGameRef<ChiyanguGame> {
  late String gridKey;
  bool broken = false;
  int hitCount = 0;
  bool tapped = false; // ✅ 加锁防连点

  final List<PolygonComponent> cracks = [];
  late RectangleComponent fillRect;

  bool get isBroken => hitCount >= 3;

  RockCellComponent({
    required Vector2 position,
    required double size,
    required this.gridKey,
  }) : super(position: position, size: Vector2.all(size));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fillRect = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF888888),
    );
    add(fillRect);

    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (broken || gameRef.isShifting) return; // ✅ 只判断是否已经碎 + 正在移动
    if (!gameRef.canBreak(gridKey)) return;

    gameRef.lastTappedKey = gridKey; // ✅ 记录本次点击

    final globalClick = absolutePosition + size / 2;

    gameRef.add(PickaxeEffectComponent(
      targetPosition: globalClick,
      onFinish: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _onPickaxeStrike(event.localPosition, shouldShift: true);
      },
    ));
  }

  void externalBreak() {
    if (broken) return;
    _onPickaxeStrike(size / 2, shouldShift: false); // ❌ 外部触发不引发 shift
  }

  void _onPickaxeStrike(Vector2 clickPoint, {required bool shouldShift}) {
    hitCount++;
    if (hitCount <= 2) {
      final segments = _generateFracturePolygon(clickPoint);
      for (final c in segments) {
        add(c);
        cracks.add(c);
      }
    } else {
      _breakBlock(shouldShift: shouldShift);
    }
  }

  void _breakBlock({required bool shouldShift}) {
    if (broken) return; // ✅ 防止重复执行

    broken = true;       // ✅ 第三击标记为碎
    removeFromParent();  // ✅ 从地图中移除
    cracks.forEach((e) => e.removeFromParent());
    cracks.clear();

    final debris = _createShatteredDebris();
    for (final frag in debris) {
      gameRef.add(frag);
    }

    gameRef.add(_showSpiritStoneReward(absolutePosition + size / 2));

    if (shouldShift) {
      gameRef.tryShiftIfNeeded(gridKey, onlyIfTapped: true); // ✅ 第三击后触发 shift
    }
  }

  List<PolygonComponent> _generateFracturePolygon(Vector2 from) {
    final List<PolygonComponent> segments = [];
    final rand = Random();
    Vector2 current = from;
    final baseDir = (Vector2(
      rand.nextDouble() - 0.5,
      rand.nextDouble() - 0.5,
    )).normalized();
    final count = 4 + rand.nextInt(3);
    double baseWidth = 6;

    for (int i = 0; i < count; i++) {
      final dir = baseDir + Vector2(
        (rand.nextDouble() - 0.5) * 0.5,
        (rand.nextDouble() - 0.5) * 0.5,
      );
      final len = 20 + rand.nextDouble() * 10;
      final offset = dir.normalized() * len;
      final next = current + offset;

      if (next.x < 0 || next.x > size.x || next.y < 0 || next.y > size.y) break;

      final mid = (current + next) / 2;
      final angle = offset.angleTo(Vector2(1, 0));
      final w1 = baseWidth, w2 = baseWidth * 0.5;

      final points = [
        Vector2(-len / 2, -w1 / 2),
        Vector2(len / 2, -w2 / 2),
        Vector2(len / 2, w2 / 2),
        Vector2(-len / 2, w1 / 2),
      ];

      final shadow = PolygonComponent(
        points,
        paint: Paint()..color = Colors.black.withOpacity(0.3),
        position: mid + Vector2(1, 1),
        angle: angle,
        anchor: Anchor.center,
        priority: 199,
      );
      final crack = PolygonComponent(
        points,
        paint: Paint()..color = Colors.black,
        position: mid,
        angle: angle,
        anchor: Anchor.center,
        priority: 200,
      );

      segments.add(shadow);
      segments.add(crack);

      current = next;
      baseWidth *= 0.7;
    }

    return segments;
  }

  List<Component> _createShatteredDebris() {
    final fragments = <Component>[];
    final count = 5 + Random().nextInt(3);
    final polygons = _generateShatteredPolygons(size, count);

    for (int i = 0; i < polygons.length; i++) {
      final frag = PolygonComponent(
        polygons[i],
        paint: Paint()..color = const Color(0xFF555555),
        position: absolutePosition,
        anchor: Anchor.topLeft,
      );

      final delay = i * 0.05;
      final targetY = gameRef.size.y + 100;
      final randomX = (Random().nextDouble() - 0.5) * 60;

      frag.add(MoveEffect.to(
        Vector2(frag.x + randomX, targetY),
        EffectController(
          duration: 1.2,
          startDelay: delay,
          curve: Curves.easeIn,
        ),
        onComplete: () => frag.removeFromParent(),
      ));

      frag.add(RotateEffect.by(
        (Random().nextDouble() - 0.5) * pi / 2,
        EffectController(duration: 1.2),
      ));

      fragments.add(frag);
    }

    return fragments;
  }

  Component _showSpiritStoneReward(Vector2 pos) {
    final text = TextComponent(
      text: '+1 下品灵石',
      position: pos,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.yellow, fontSize: 14),
      ),
    );

    text.add(
      MoveEffect.by(
        Vector2(0, -30),
        EffectController(duration: 0.8),
        onComplete: () => text.removeFromParent(),
      ),
    );

    return text;
  }

  List<List<Vector2>> _generateShatteredPolygons(Vector2 size, int count) {
    final centerPoints = List.generate(
      count,
          (_) => Vector2(
        Random().nextDouble() * size.x,
        Random().nextDouble() * size.y,
      ),
    );

    const int resolution = 20;
    final stepX = size.x / resolution;
    final stepY = size.y / resolution;

    final Map<int, List<Vector2>> polygonMap = {};
    for (int i = 0; i <= resolution; i++) {
      for (int j = 0; j <= resolution; j++) {
        final p = Vector2(i * stepX, j * stepY);
        int nearest = 0;
        double minDist = double.infinity;

        for (int k = 0; k < centerPoints.length; k++) {
          final d = p.distanceTo(centerPoints[k]);
          if (d < minDist) {
            minDist = d;
            nearest = k;
          }
        }

        polygonMap.putIfAbsent(nearest, () => []).add(p);
      }
    }

    return polygonMap.values.map(_convexHull).toList();
  }

  List<Vector2> _convexHull(List<Vector2> points) {
    final sorted = [...points]
      ..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));

    final lower = <Vector2>[], upper = <Vector2>[];

    for (final p in sorted) {
      while (lower.length >= 2 &&
          _cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          _cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return lower + upper;
  }

  double _cross(Vector2 o, Vector2 a, Vector2 b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }
}
