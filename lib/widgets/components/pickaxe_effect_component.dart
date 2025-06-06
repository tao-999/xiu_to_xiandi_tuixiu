// 📦 lib/widgets/components/pickaxe_effect_component.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class PickaxeEffectComponent extends TextComponent with HasGameRef {
  final Vector2 targetPosition;
  final VoidCallback onFinish;

  PickaxeEffectComponent({
    required this.targetPosition,
    required this.onFinish,
  }) : super(
    text: '⛏️',
    anchor: Anchor.center,
    priority: 10,
    textRenderer: TextPaint(
      style: TextStyle(
        fontSize: 32, // ✅ 改这个值，变大变骚
      ),
    ),
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = targetPosition;

    // 抬起
    final lift = MoveEffect.by(
      Vector2(0, -8),
      EffectController(duration: 0.1, curve: Curves.easeOut),
    );

    // 猛砸
    final smash = MoveEffect.by(
      Vector2(0, 24),
      EffectController(duration: 0.15, curve: Curves.bounceIn),
    );

    // 回弹 + 完成
    final bounceBack = MoveEffect.by(
      Vector2(0, -8),
      EffectController(duration: 0.1, curve: Curves.easeOut),
      onComplete: () {
        removeFromParent();
        onFinish();
      },
    );

    // 依次添加：抬起 → 猛砸 → 回弹
    add(lift
      ..onComplete = () {
        add(smash
          ..onComplete = () {
            add(bounceBack);
          });
      });
  }
}
