import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../models/character.dart';
import '../../utils/player_sprite_util.dart';
import 'hp_bar_wrapper.dart';
import 'hell_monster_component.dart';

class HellPlayerComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  HellPlayerComponent({
    required this.safeZoneCenter,
    required this.safeZoneRadius,
    required this.onRevived,
    required this.isWaveCleared,
    this.onHellPassed,
  }) : super(anchor: Anchor.center);

  final Vector2 safeZoneCenter;
  final double safeZoneRadius;
  final VoidCallback onRevived;
  final VoidCallback? onHellPassed;
  final bool Function() isWaveCleared;

  Vector2? targetPosition;
  final double moveSpeed = 200.0;

  late Character _player;
  late int hp;
  late int maxHp;
  late int atk;
  late int def;

  bool isDead = false;

  late HpBarWrapper _hpBar;

  bool get isInSafeZone =>
      (absolutePosition - safeZoneCenter).length <= safeZoneRadius;

  double _attackCooldown = 0; // 🌟 新增攻击冷却

  @override
  Future<void> onLoad() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;
    _player = player;

    final spritePath = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(spritePath);

    final sizeMultiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(24.0 * sizeMultiplier);

    maxHp = PlayerStorage.getHp(_player);
    hp = maxHp;
    atk = PlayerStorage.getAtk(_player);
    def = PlayerStorage.getDef(_player);

    add(RectangleHitbox()..collisionType = CollisionType.active);

    _hpBar = HpBarWrapper(
      ratio: () => hp / maxHp,
      currentHp: () => hp,
      barColor: Colors.green,       // ✅ 绿色血条
      textColor: Colors.green,      // ✅ 绿色数值
    )
      ..scale.x = 1
      ..priority = 999;

    Future.microtask(() {
      parent?.add(_hpBar);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    _attackCooldown -= dt;

    _hpBar.position = absolutePosition + Vector2(0, -size.y / 2 - 6);

    if (!isDead && targetPosition != null) {
      final toTarget = targetPosition! - position;
      final distance = toTarget.length;
      if (distance < moveSpeed * dt) {
        position = targetPosition!;
        targetPosition = null;
      } else {
        position += toTarget.normalized() * moveSpeed * dt;
      }
    }

    if (isInSafeZone && !isDead) {
      if (hp < maxHp) {
        hp = maxHp;
        _showFloatingText('🌿 安全区恢复满血！', color: Colors.greenAccent);
      }
    }

    if (isInSafeZone && !isDead && isWaveCleared()) {
      onHellPassed?.call();
    }
  }

  void moveTo(Vector2 target) {
    if (isDead) return;

    targetPosition = target;
    final delta = target - position;
    scale.x = delta.x < 0 ? -1 : 1;
  }

  void receiveDamage(int damage) {
    if (isDead) return;

    final reduced = (damage - def);
    if (reduced <= 0) {
      _showFloatingText('格挡', color: Colors.grey);
      return;
    }

    hp = (hp - reduced).clamp(0, maxHp);
    _showFloatingText('-$reduced', color: Colors.redAccent);
    _triggerDamageEffect();

    if (hp <= 0 && !isDead) {
      isDead = true;
      _onDeath();
    }
  }

  void _onDeath() {
    _showFloatingText('你死了', color: Colors.purpleAccent);
    targetPosition = null;

    for (int i = 3; i >= 1; i--) {
      Future.delayed(Duration(seconds: 4 - i), () {
        _showFloatingText('$i 秒后复活', color: Colors.orangeAccent);
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      _reviveAtSafeZone();
      _showFloatingText('已复活', color: Colors.greenAccent);
    });
  }

  void _reviveAtSafeZone() {
    isDead = false;
    hp = maxHp;
    position = safeZoneCenter.clone();

    add(
      OpacityEffect.to(
        0.3,
        EffectController(duration: 0.1, reverseDuration: 0.1, repeatCount: 6),
        onComplete: () => opacity = 1.0,
      ),
    );

    onRevived();
  }

  void _showFloatingText(String text, {Color color = Colors.white}) {
    final textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 12,
          color: color,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    )
      ..anchor = Anchor.center
      ..position = absolutePosition + Vector2(0, -size.y / 2 - 12)
      ..priority = 999;

    game.add(textComponent);

    textComponent.add(
      MoveEffect.by(
        Vector2(0, -16),
        EffectController(duration: 0.6, curve: Curves.easeOut),
        onComplete: () => textComponent.removeFromParent(),
      ),
    );
  }

  void _triggerDamageEffect() {
    // 可加角色受伤效果
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);

    if (other is HellMonsterComponent && !isDead) {
      if (_attackCooldown <= 0) {
        final damage = atk;
        other.receiveDamage(damage, from: absolutePosition);
        _attackCooldown = 0.5; // 🌟 每0.5秒打一刀
      }

      final delta = position - other.position;
      if (delta.length > 0) {
        final pushBack = delta.normalized() * 4;
        position += pushBack;
      }
    }
  }
}
