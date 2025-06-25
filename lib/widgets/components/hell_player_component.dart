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
  }) : super(anchor: Anchor.center);

  Vector2? targetPosition;
  final double moveSpeed = 200.0;

  late Character _player;
  late int hp;
  late int maxHp;
  late int atk;
  late int def;

  late HpBarWrapper _hpBar;

  final Vector2 safeZoneCenter;
  final double safeZoneRadius;

  bool get isInSafeZone =>
      (absolutePosition - safeZoneCenter).length <= safeZoneRadius;

  @override
  Future<void> onLoad() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;
    _player = player;

    final spritePath = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(spritePath);

    final sizeMultiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(18.0 * sizeMultiplier);
    position = Vector2.all(1024);

    maxHp = PlayerStorage.getHp(_player);
    hp = maxHp;
    atk = PlayerStorage.getAtk(_player);
    def = PlayerStorage.getDef(_player);

    add(RectangleHitbox()..collisionType = CollisionType.active);

    _hpBar = HpBarWrapper(ratio: () => hp / maxHp)
      ..scale.x = 1
      ..priority = 999;
    Future.microtask(() {
      parent?.add(_hpBar);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hpBar.position = absolutePosition + Vector2(0, -size.y / 2 - 6);

    if (targetPosition != null) {
      final toTarget = targetPosition! - position;
      final distance = toTarget.length;
      if (distance < moveSpeed * dt) {
        position = targetPosition!;
        targetPosition = null;
      } else {
        position += toTarget.normalized() * moveSpeed * dt;
      }
    }
  }

  void moveTo(Vector2 target) {
    targetPosition = target;

    // ✅ 左右方向镜像控制
    final delta = target - position;
    scale.x = delta.x < 0 ? -1 : 1;
  }

  void receiveDamage(int damage) {
    final reduced = (damage - def);

    if (reduced <= 0) {
      _showFloatingText('格挡', color: Colors.grey);
      return;
    }

    hp = (hp - reduced).clamp(0, maxHp);

    // ✅ 受击伤害飘字
    _showFloatingText('-$reduced', color: Colors.redAccent);

    // ✅ 闪红 or 动效
    _triggerDamageEffect();

    if (hp <= 0) {
      _onDeath();
    }
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
    // 你可以加入红屏、闪光、震屏等逻辑
    // 比如让血条震动、贴图变红闪烁
    // 这里只是预留接口
  }

  void _onDeath() {
    _showFloatingText('你死了', color: Colors.purpleAccent);
    // ❌ 播放死亡动画 or 弹窗
  }

  int get power => atk + def + hp ~/ 10;

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);

    if (other is HellMonsterComponent) {
      final damage = (atk - other.def).clamp(0, atk);
      other.receiveDamage(damage, from: absolutePosition); // ✅ 一句就够了！

      print('⚔️ 玩家攻击怪物 [${other.id}]，造成 $damage 点伤害');
    }
  }
}
