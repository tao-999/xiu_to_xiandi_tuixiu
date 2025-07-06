import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import '../../services/hell_service.dart';
import '../../services/player_storage.dart';
import '../../services/resources_storage.dart';
import 'hell_player_component.dart';
import 'youming_hell_map_game.dart';
import 'hp_bar_wrapper.dart';

class HellMonsterComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<YoumingHellMapGame> {
  final int id;
  final int level;
  final int waveIndex;
  final bool isBoss;

  PositionComponent? _target;
  double _moveSpeed = 10;

  int atk = 0;
  int def = 0;
  int hp = 0;
  int maxHp = 0;

  Vector2? _safeZoneCenter;
  double _safeZoneRadius = 0;

  bool _isWandering = false;
  double _wanderTimer = 0;
  Vector2 _wanderDirection = Vector2.zero();

  bool _isTouchingPlayer = false;

  late final TextComponent _damageText;
  final Random _rng = Random();

  HellMonsterComponent({
    required this.id,
    required this.level,
    required this.waveIndex,
    this.isBoss = false,
    required Vector2 position,
    int? atk,
    int? def,
    int? hp,
  }) : super(
    position: position,
    anchor: Anchor.center,
  ) {
    final attr = HellService.calculateMonsterAttributes(
      level: level,
      waveIndex: waveIndex,
      isBoss: isBoss,
    );

    this.atk = atk ?? attr['atk']!;
    this.def = def ?? attr['def']!;
    this.hp = hp ?? attr['hp']!;
    this.maxHp = this.hp;
  }

  @override
  Future<void> onLoad() async {
    int normalizedLevel = (level - 1) % 18 + 1;
    sprite = await Sprite.load('hell/diyu_$normalizedLevel.png');
    size = isBoss ? Vector2.all(32) * 2 : Vector2.all(32);
    add(RectangleHitbox()..collisionType = CollisionType.active);

    add(
      HpBarWrapper(
        ratio: () => hp / maxHp,
        width: size.x,
        height: isBoss ? 4 : 2,
      )
        ..position = Vector2(0, -size.y / 2 - 6)
        ..anchor = Anchor.topLeft,
    );

    _damageText = TextComponent(
      text: '',
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -size.y / 2 - 2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.red,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black),
          ],
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

    final toSafeCenter = position - _safeZoneCenter!;
    final distToSafe = toSafeCenter.length;

    if (distToSafe < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter.normalized() * (_safeZoneRadius + 1.0);
      return; // 在安全区直接退出
    }

    final playerPos = _target!.position;
    final distToPlayer = (playerPos - position).length;

    if ((playerPos - _safeZoneCenter!).length < _safeZoneRadius || distToPlayer > 200) {
      // 游荡逻辑
      _isWandering = true;
      _wanderTimer -= dt;

      if (_wanderTimer <= 0) {
        _wanderTimer = 1.5 + _rng.nextDouble() * 2.0;
        final angle = _rng.nextDouble() * 2 * pi;
        _wanderDirection = Vector2(cos(angle), sin(angle));
      }

      position += _wanderDirection * (_moveSpeed * 0.4) * dt;
    } else {
      // 追击逻辑
      _isWandering = false;
      final toPlayer = playerPos - position;
      if (toPlayer.length > 1e-2) {
        position += toPlayer.normalized() * _moveSpeed * dt;
      }
    }

    // 安全区外约束
    final toSafeCenter2 = position - _safeZoneCenter!;
    if (toSafeCenter2.length < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter2.normalized() * (_safeZoneRadius + 1.0);
    }

    // ✅地图边界限制
    position.x = position.x.clamp(0, game.mapRoot.size.x);
    position.y = position.y.clamp(0, game.mapRoot.size.y);
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);

    if (other is HellPlayerComponent && !other.isDead && !_isTouchingPlayer) {
      final damage = atk;
      other.receiveDamage(damage);
      _isTouchingPlayer = true;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is HellPlayerComponent) {
      _isTouchingPlayer = false;
    }
  }

  void _giveReward() async {
    final base = 10 + (level - 1);
    final reward = isBoss ? base * 2 : base;

    ResourcesStorage.add('spiritStoneMid', BigInt.from(reward));
    print('💰 击杀奖励：$reward 个中品灵石');

    final prev = await HellService.loadSpiritStoneReward();
    await HellService.saveSpiritStoneReward(prev + reward);
  }

  void onDeath({Vector2? from}) {
    print('💀 怪物 #$id 死亡触发！当前波次：$waveIndex，剩余HP: $hp');

    _giveReward();
    game.checkWaveProgress();

    if (from != null) {
      final direction = (position - from).normalized();
      final knockbackTarget = position + direction * 480;

      final effect = MoveEffect.to(
        knockbackTarget,
        EffectController(duration: 1.0, curve: Curves.easeOut),
      )..onComplete = () {
        removeFromParent();
      };

      Future.microtask(() {
        if (isMounted) add(effect);
      });
    } else {
      removeFromParent();
    }
  }

  void receiveDamage(int damage, {Vector2? from}) {
    final reduced = damage - def;

    if (reduced <= 0) {
      _damageText.text = '格挡';
      _damageText.position = Vector2(0, -size.y / 2 - 2);

      if (!_damageText.isMounted) {
        add(_damageText);
      }

      _damageText.add(
        MoveByEffect(
          Vector2(0, -16),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOut,
          ),
          onComplete: () => _damageText.removeFromParent(),
        ),
      );
      return;
    }

    hp -= reduced;

    _damageText.text = '-$reduced';
    _damageText.position = Vector2(0, -size.y / 2 - 2);

    if (!_damageText.isMounted) {
      add(_damageText);
    }

    _damageText.add(
      MoveByEffect(
        Vector2(0, -16),
        EffectController(
          duration: 0.4,
          curve: Curves.easeOut,
        ),
        onComplete: () => _damageText.removeFromParent(),
      ),
    );

    if (hp <= 0) {
      onDeath(from: from);
    }
  }

  int get power {
    return PlayerStorage.calculatePower(
      hp: hp,
      atk: atk,
      def: def,
    );
  }
}
