import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'pickaxe_effect_component.dart';
import 'chiyangu_game.dart';

class RockCellComponent extends PositionComponent
    with TapCallbacks, HasGameRef<ChiyanguGame> {
  final String gridKey;
  bool broken = false;
  int hitCount = 0;

  SpriteComponent? rockSprite;
  SpriteComponent? crackOverlay;

  bool get isBroken => hitCount >= 2;

  RockCellComponent({
    required Vector2 position,
    required double size,
    required this.gridKey,
  }) : super(position: position, size: Vector2.all(size));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _updateSpriteByHitCount();
  }

  Future<void> _updateSpriteByHitCount() async {
    if (isBroken) {
      broken = true;
      removeFromParent();
      return;
    }

    await _setNormalSprite();
    if (hitCount == 1) {
      await _addCrackOverlay();
    }
  }

  Future<void> _setNormalSprite() async {
    final sprite = await gameRef.loadSprite('chiyangu_shitou.webp');
    rockSprite?.removeFromParent();
    rockSprite = SpriteComponent(sprite: sprite, size: size);
    add(rockSprite!);
  }

  Future<void> _addCrackOverlay() async {
    if (crackOverlay != null) return;
    final sprite = await gameRef.loadSprite('chiyangu_shitou_liefeng.png');
    crackOverlay = SpriteComponent(sprite: sprite, size: size);
    add(crackOverlay!);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (broken || gameRef.isShifting) return;
    if (!gameRef.canBreak(gridKey)) return;

    gameRef.lastTappedKey = gridKey;
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
    _onPickaxeStrike(size / 2, shouldShift: false);
  }

  void _onPickaxeStrike(Vector2 clickPoint, {required bool shouldShift}) {
    hitCount++;
    gameRef.saveCurrentState(); // ✅ 每次敲击后保存状态

    if (hitCount == 1) {
      _addCrackOverlay();
    } else {
      _breakBlock(shouldShift: shouldShift);
    }
  }

  void _breakBlock({required bool shouldShift}) {
    if (broken) return;
    broken = true;
    removeFromParent();

    final debris = _createShatteredDebris();
    for (final frag in debris) {
      gameRef.add(frag);
    }

    gameRef.add(_showSpiritStoneReward(absolutePosition + size / 2));

    if (shouldShift) {
      gameRef.tryShiftIfNeeded(gridKey, onlyIfTapped: true);
    }
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
        onComplete: () => frag.removeFromParent(), // ✅ 注意这里改位置了
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
        onComplete: () => text.removeFromParent(), // ✅ Flame 1.29 新语法
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

  Map<String, dynamic> toStorage() {
    return {
      'type': 'rock',
      'breakLevel': hitCount.clamp(0, 2),
    };
  }

  Future<void> restoreFromStorage(int level) async {
    hitCount = level.clamp(0, 2);
    await _updateSpriteByHitCount();
  }
}
