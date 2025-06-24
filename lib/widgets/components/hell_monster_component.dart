import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
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
    sprite = await Sprite.load('hell/diyu_$level.png');
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

    // 创建编号显示文本
    _idText = TextComponent(
      text: 'ID: $id',  // 显示怪物编号
      textRenderer: TextPaint(
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    )..position = Vector2(0, -size.y / 2 - 16); // 设置文本位置，稍微在血条上方
    add(_idText!);  // 将文本添加到怪物组件中
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

  void receiveDamage(int damage) {
    final reduced = (damage - def).clamp(0, damage);
    hp -= reduced;

    if (hp <= 0) {
      removeFromParent();
      game.checkWaveProgress();
    }
  }

  int get power => atk + def + hp ~/ 10;
}
