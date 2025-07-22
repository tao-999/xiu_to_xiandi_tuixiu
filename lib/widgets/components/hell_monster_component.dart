import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import '../../services/player_storage.dart';
import 'hell_player_component.dart';
import 'hp_bar_wrapper.dart';
import 'youming_hell_map_game.dart';

class HellMonsterComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<YoumingHellMapGame> {
  final int id;
  final int level;
  final bool isBoss;
  void Function()? onDeathCallback;

  int atk;
  int def;
  int hp;
  int maxHp;

  double _moveSpeed = 10;
  Vector2? _safeZoneCenter;
  double _safeZoneRadius = 0;

  PositionComponent? _target;
  bool _isWandering = false;
  double _wanderTimer = 0;
  Vector2 _wanderDirection = Vector2.zero();
  bool _isTouchingPlayer = false;
  double _attackCooldown = 0;

  final Random _rng = Random();

  late final HpBarWrapper _hpBar;
  late final TextComponent _damageText;

  bool get isDead => hp <= 0;

  HellMonsterComponent({
    required this.id,
    required this.level,
    required this.isBoss,
    required Vector2 position,
    required this.hp,
    required this.maxHp,
    required this.atk,
    required this.def,
    this.onDeathCallback,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    int normalizedLevel = (level - 1) % 18 + 1;
    sprite = await Sprite.load('hell/diyu_$normalizedLevel.png');
    size = isBoss ? Vector2.all(32) * 2 : Vector2.all(32);
    add(RectangleHitbox()..collisionType = CollisionType.active);

    _hpBar = HpBarWrapper(width: size.x, height: isBoss ? 4 : 2)
      ..position = Vector2(0, -size.y / 2 - 6)
      ..anchor = Anchor.topLeft;

    Future.microtask(() {
      add(_hpBar);
      _hpBar.setStats(currentHp: hp, maxHp: maxHp, atk: atk, def: def);
    });

    _damageText = TextComponent(
      text: '',
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -size.y / 2 - 2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.red,
          shadows: [Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black)],
        ),
      ),
    )..priority = 999;
    add(_damageText);
  }

  void trackTarget(
      PositionComponent target, {
        required double speed,
        required Vector2 safeCenter,
        required double safeRadius,
      }) {
    _target = target;
    _moveSpeed = speed;
    _safeZoneCenter = safeCenter;
    _safeZoneRadius = safeRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted || _target == null || _safeZoneCenter == null) return;

    _attackCooldown -= dt;
    final toSafeCenter = position - _safeZoneCenter!;
    final distToSafe = toSafeCenter.length;

    if (distToSafe < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter.normalized() * (_safeZoneRadius + 1.0);
      return;
    }

    final playerPos = _target!.position;
    final distToPlayer = (playerPos - position).length;

    if ((playerPos - _safeZoneCenter!).length < _safeZoneRadius || distToPlayer > 250) {
      _isWandering = true;
      _wanderTimer -= dt;

      if (_wanderTimer <= 0) {
        _wanderTimer = 1.5 + _rng.nextDouble() * 2.0;
        final angle = _rng.nextDouble() * 2 * pi;
        _wanderDirection = Vector2(cos(angle), sin(angle));
      }

      position += _wanderDirection * (_moveSpeed * 0.5) * dt;
    } else {
      _isWandering = false;
      final toPlayer = playerPos - position;
      if (toPlayer.length > 1e-2) {
        position += toPlayer.normalized() * (_moveSpeed * 2.0) * dt;
      }
    }

    final toSafeCenter2 = position - _safeZoneCenter!;
    if (toSafeCenter2.length < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter2.normalized() * (_safeZoneRadius + 1.0);
    }

    position.x = position.x.clamp(0, game.mapRoot.size.x);
    position.y = position.y.clamp(0, game.mapRoot.size.y);

    if (_isTouchingPlayer && _attackCooldown <= 0) {
      if (_target is HellPlayerComponent) {
        final player = _target as HellPlayerComponent;
        if (!player.isDead) {
          player.receiveDamage(atk);
          _attackCooldown = 1.0;
        }
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is HellPlayerComponent && !other.isDead) {
      _isTouchingPlayer = true;
      _attackCooldown = 0;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is HellPlayerComponent) {
      _isTouchingPlayer = false;
    }
  }

  void onDeath({Vector2? from}) {
    onDeathCallback?.call();

    final effect = from != null
        ? MoveEffect.to(
      position + (position - from).normalized() * 480,
      EffectController(duration: 1.0, curve: Curves.easeOut),
    )
        : null;

    Future.microtask(() {
      if (!isMounted) return;
      if (effect != null) {
        effect.onComplete = () => removeFromParent();
        add(effect);
      } else {
        removeFromParent();
      }
    });
  }

  void receiveDamage(int damage, {Vector2? from}) {
    final reduced = damage - def;
    if (reduced <= 0) {
      _showDamageText('格挡');
      return;
    }

    hp -= reduced;
    _hpBar.setStats(currentHp: hp, maxHp: maxHp, atk: atk, def: def);
    _showDamageText('-$reduced');

    if (hp <= 0) {
      onDeath(from: from);
    }
  }

  void _showDamageText(String text) {
    _damageText.text = text;
    _damageText.position = Vector2(0, -size.y / 2 - 2);
    _damageText.add(
      SequenceEffect([
        MoveByEffect(Vector2(0, -16), EffectController(duration: 0.4)),
        RemoveEffect(onComplete: () => _damageText.text = ''),
      ]),
    );
  }

  int get power => PlayerStorage.calculatePower(hp: hp, atk: atk, def: def);
}

