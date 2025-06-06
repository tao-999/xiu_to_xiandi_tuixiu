import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'pickaxe_effect_component.dart';
import 'chiyangu_game.dart';

class DirtCellComponent extends PositionComponent
    with TapCallbacks, HasGameRef<ChiyanguGame> {
  final int depth;
  late String gridKey;
  bool broken = false;
  bool tapped = false; // ✅ 点击加锁
  late SpriteComponent fillSprite;

  DirtCellComponent({
    required Vector2 position,
    required double size,
    required this.depth,
    required this.gridKey,
  }) : super(position: position, size: Vector2.all(size));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final sprite = await gameRef.loadSprite(_getSoilSpritePath(depth));
    fillSprite = SpriteComponent(sprite: sprite, size: size);
    add(fillSprite);

    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    ));

    // ✅ 可视化调试 key（如不需要可注释掉）
    add(TextComponent(
      text: gridKey,
      anchor: Anchor.bottomLeft,
      position: Vector2(2, size.y - 2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (tapped || broken || gameRef.isShifting) return;
    if (!gameRef.canBreak(gridKey)) return;

    gameRef.lastTappedKey = gridKey;
    tapped = true;

    final globalClick = absolutePosition + size / 2;

    gameRef.add(PickaxeEffectComponent(
      targetPosition: globalClick,
      onFinish: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _breakBlock(shouldShift: true);
        gameRef.breakAdjacent(gridKey, fromDirt: true);
      },
    ));
  }

  void externalBreak() {
    if (broken) return;
    debugPrint('🔥 爆格子 $gridKey');
    _breakBlock(shouldShift: false);
  }

  void _breakBlock({required bool shouldShift}) {
    broken = true;
    removeFromParent();

    final debris = _createShatteredDebris();
    for (final frag in debris) {
      gameRef.add(frag);
    }

    if (shouldShift) {
      gameRef.tryShiftIfNeeded(gridKey, onlyIfTapped: true);
    }
  }

  // ✅ 存档支持
  Map<String, dynamic> toStorage() {
    return {
      'type': 'dirt',
      'breakLevel': broken ? 1 : 0,
    };
  }

  // ✅ 加载支持
  void restoreFromStorage(int level) {
    if (level >= 1) {
      broken = true;
      removeFromParent();
    }
  }

  List<Component> _createShatteredDebris() {
    final fragments = <Component>[];
    final count = 5 + Random().nextInt(3);
    final polygons = _generateShatteredPolygons(size, count);

    for (int i = 0; i < polygons.length; i++) {
      final vertices = polygons[i];
      if (vertices.length < 3) continue;

      final frag = PolygonComponent(
        vertices,
        paint: Paint()..color = const Color(0xFF8B5A2B),
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

  List<List<Vector2>> _generateShatteredPolygons(Vector2 size, int count) {
    final centerPoints = List.generate(
      count,
          (_) => Vector2(
        Random().nextDouble() * size.x,
        Random().nextDouble() * size.y,
      ),
    );

    const resolution = 20;
    final stepX = size.x / resolution;
    final stepY = size.y / resolution;
    final polygonMap = <int, List<Vector2>>{};

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

  String _getSoilSpritePath(int depth) {
    if (depth >= 10000000) return 'chiyangu_youmingtu.webp';
    if (depth >= 1000000) return 'chiyangu_chiyantu.webp';
    if (depth >= 100000) return 'chiyangu_tierang.webp';
    if (depth >= 10000) return 'chiyangu_hetu.webp';
    return 'chiyangu_nitu.webp';
  }
}
