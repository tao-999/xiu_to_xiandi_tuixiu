import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'youming_hell_map_game.dart';
import 'hp_bar_wrapper.dart'; // ✅ 引入你封装好的血条组件

class HellMonsterComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<YoumingHellMapGame> {
  final int id; // 添加编号
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

  TextComponent? _idText;  // 用来显示编号的文本
  late final TextComponent _damageText;

  HellMonsterComponent({
    required this.id, // 初始化时传入编号
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
    final effectiveLevel = isBoss ? level : level * (waveIndex + 1);
    this.atk = atk ?? (isBoss ? 100 : 20 + effectiveLevel * 2);
    this.def = def ?? (isBoss ? 50 : 10 + effectiveLevel);
    this.hp = hp ?? (isBoss ? 500 : 100 + effectiveLevel * 10);
    this.maxHp = this.hp;
  }

  @override
  Future<void> onLoad() async {
    // 计算 level 在 1-18 范围内循环的图片索引
    int normalizedLevel = (level - 1) % 18 + 1;

    // 根据循环后的 level 加载图片
    sprite = await Sprite.load('hell/diyu_$normalizedLevel.png');
    size = isBoss ? Vector2.all(32) * 2 : Vector2.all(32);
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // ✅ 使用封装血条组件 HpBarWrapper
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

    final toSafeCenter = position - _safeZoneCenter!;
    if (toSafeCenter.length < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter.normalized() * (_safeZoneRadius + 1.0);
    }

    final playerPos = _target!.position;
    final playerInSafeZone = (playerPos - _safeZoneCenter!).length < _safeZoneRadius;

    if (playerInSafeZone) {
      _isWandering = true;
      _wanderTimer -= dt;

      if (_wanderTimer <= 0) {
        _wanderTimer = 1.5 + Random().nextDouble() * 2.0;
        final angle = Random().nextDouble() * 2 * pi;
        _wanderDirection = Vector2(cos(angle), sin(angle));
      }

      position += _wanderDirection.normalized() * (_moveSpeed * 0.4) * dt;
    } else {
      _isWandering = false;
      final toPlayer = playerPos - position;
      if (toPlayer.length > 1e-2) {
        final move = toPlayer.normalized() * _moveSpeed * dt;
        position += move;
      }
    }

    final toSafeCenter2 = position - _safeZoneCenter!;
    if (toSafeCenter2.length < _safeZoneRadius) {
      position = _safeZoneCenter! + toSafeCenter2.normalized() * (_safeZoneRadius + 1.0);
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is HellMonsterComponent && other != this) {
      final offset = (position - other.position).normalized() * 2;
      position += offset;
    }
    super.onCollision(points, other);
  }

  void receiveDamage(int damage, {Vector2? from}) {
    final reduced = damage - def;
    if (reduced <= 0) return; // ❌ 破不了防，不处理

    hp -= reduced;

    // ✅ 展示飘字（文字组件需要提前在 onLoad 中初始化 _damageText）
    _damageText.text = '-$reduced';
    _damageText.position = Vector2(0, -size.y / 2 - 2);

    if (!_damageText.isMounted) {
      add(_damageText);
    }

    _damageText.add(
      MoveByEffect(
        Vector2(0, -16),
        EffectController(duration: 0.4, curve: Curves.easeOut),
        onComplete: () {
          _damageText.removeFromParent(); // ✅ 及时隐藏
        },
      ),
    );

    // ✅ 怪物死亡处理
    if (hp <= 0) {
      if (from != null) {
        final direction = (position - from).normalized();
        final knockbackTarget = position + direction * 480;

        final effect = MoveEffect.to(
          knockbackTarget,
          EffectController(duration: 1.0, curve: Curves.easeOut),
        )..onComplete = () {
          removeFromParent();
          game.checkWaveProgress();
        };

        Future.microtask(() {
          if (isMounted) add(effect);
        });
      } else {
        removeFromParent();
        game.checkWaveProgress();
      }
    }
  }

  int get power => atk + def + hp ~/ 10;
}
