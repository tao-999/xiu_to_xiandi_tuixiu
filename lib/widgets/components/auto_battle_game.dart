import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class AutoBattleGame extends FlameGame {
  late TextComponent player;
  final List<TextComponent> enemies = [];
  final List<TextComponent> enemiesToRemove = [];
  final Random rng = Random();
  late Timer spawnTimer;
  late Timer attackTimer;

  @override
  Future<void> onLoad() async {
    // 🧘 Main player
    player = TextComponent(
      text: '🧘',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 48)),
    )
      ..anchor = Anchor.center
      ..position = size / 2;
    add(player);

    // 👹 Spawn 3 enemies every 0.5s
    spawnTimer = Timer(1.0, repeat: true, onTick: () {
      for (int i = 0; i < 2; i++) {
        _spawnEnemy();
      }
    })..start();

    // ⚔️ Auto attack
    attackTimer = Timer(1.0, repeat: true, onTick: _fireProjectile)..start();
  }

  void _spawnEnemy() {
    final emojiList = ['👹', '👾', '💀', '🐍', '🦙'];
    final emoji = emojiList[rng.nextInt(emojiList.length)];
    final enemy = TextComponent(
      text: emoji,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 36)),
    )
      ..anchor = Anchor.center
      ..position = _randomSpawnOutside();
    add(enemy);
    enemies.add(enemy);
  }

  Vector2 _randomSpawnOutside() {
    final edge = rng.nextInt(4);
    double x, y;

    switch (edge) {
      case 0: // Top
        x = rng.nextDouble() * size.x;
        y = -30;
        break;
      case 1: // Bottom
        x = rng.nextDouble() * size.x;
        y = size.y + 30;
        break;
      case 2: // Left
        x = -30;
        y = rng.nextDouble() * size.y;
        break;
      default: // Right
        x = size.x + 30;
        y = rng.nextDouble() * size.y;
        break;
    }

    return Vector2(x, y);
  }

  void _fireProjectile() {
    if (enemies.isEmpty) return;

    final target = enemies.first;
    final projectile = TextComponent(
      text: '⚔️',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24)),
      anchor: Anchor.center,
      position: player.position.clone(),
    );

    add(projectile);

    projectile.add(
      MoveEffect.to(
        target.position,
        EffectController(duration: 0.4, curve: Curves.linear),
        onComplete: () {
          if (children.contains(target)) {
            _showDamageText(target.position, damage: 999);
            if (!enemiesToRemove.contains(target)) {
              enemiesToRemove.add(target);
            }
          }
          projectile.removeFromParent();
        },
      ),
    );
  }

  void _showDamageText(Vector2 pos, {required int damage, String? text}) {
    final textComp = TextComponent(
      text: text ?? '-$damage',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      position: pos.clone(),
      anchor: Anchor.center,
    );
    add(textComp);

    textComp.add(MoveByEffect(
      Vector2(0, -20),
      EffectController(duration: 0.6),
    ));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (textComp.parent == this) {
        textComp.removeFromParent();
      }
    });
  }

  void _explodeEnemy(TextComponent enemy) {
    if (children.contains(enemy)) {
      _showDamageText(enemy.position, damage: 0, text: '💥');
      if (!enemiesToRemove.contains(enemy)) {
        enemiesToRemove.add(enemy);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer.update(dt);
    attackTimer.update(dt);

    for (final enemy in List<TextComponent>.from(enemies)) {
      final dir = (player.position - enemy.position).normalized();
      enemy.position += dir * 40 * dt;

      final distance = player.position.distanceTo(enemy.position);
      if (distance < 30) {
        _explodeEnemy(enemy);
      }
    }

    for (final enemy in enemiesToRemove) {
      if (children.contains(enemy)) {
        enemy.removeFromParent();
      }
      enemies.remove(enemy);
    }
    enemiesToRemove.clear();
  }
}