import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

import 'huanyue_player_component.dart';

final List<String> _enemyPaths = [
  'enemies/enemy_stage1_1.png',
  'enemies/enemy_stage1_2.png',
  'enemies/enemy_stage1_3.png',
  'enemies/enemy_stage1_4.png',
  'enemies/enemy_stage1_5.png',
  'enemies/enemy_stage4_1.png',
  'enemies/enemy_stage4_2.png',
  'enemies/enemy_stage4_3.png',
  'enemies/enemy_stage4_4.png',
  'enemies/enemy_stage4_5.png',
  'enemies/enemy_stage7_1.png',
  'enemies/enemy_stage7_2.png',
  'enemies/enemy_stage7_3.png',
  'enemies/enemy_stage7_4.png',
  'enemies/enemy_stage7_5.png',
];

class HuanyueEnemySpawner extends Component with HasGameReference {
  final int rows;
  final int cols;
  final double tileSize;
  final int floor;
  final int enemyCount;
  final TileManager tileManager;

  late final Random _rand;

  HuanyueEnemySpawner({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.floor,
    required this.tileManager,
    this.enemyCount = 10,
  }) {
    _rand = Random(floor);
  }

  @override
  Future<void> onLoad() async {
    print('✅ HuanyueEnemySpawner loaded (floor $floor)');

    final bossId = 'boss-floor-$floor';
    Vector2? bossPos = await HuanyueStorage.getEnemyPosition(bossId);
    if (bossPos == null) {
      bossPos = _randomValidPixelPos();
      await HuanyueStorage.saveEnemyPosition(bossId, bossPos);
    }

    if (!await HuanyueStorage.isEnemyKilled(bossId)) {
      final bossSprite = await Sprite.load(_randomEnemyPath());
      add(HuanyueEnemyComponent(
        id: bossId,
        floor: floor,
        isBoss: true,
        sprite: bossSprite,
        position: bossPos,
        size: Vector2.all(60),
      )..priority = 10);
    }

    int placed = 0;
    while (placed < enemyCount) {
      final id = 'enemy-${floor}-$placed';
      if (await HuanyueStorage.isEnemyKilled(id)) {
        placed++;
        continue;
      }

      Vector2? pos = await HuanyueStorage.getEnemyPosition(id);
      if (pos == null) {
        pos = _randomValidPixelPos();
        await HuanyueStorage.saveEnemyPosition(id, pos);
      }

      final sprite = await Sprite.load(_randomEnemyPath());
      add(HuanyueEnemyComponent(
        id: id,
        floor: floor,
        isBoss: false,
        sprite: sprite,
        position: pos,
        size: Vector2.all(28),
      )..priority = 10);

      placed++;
    }
  }

  String _randomEnemyPath() {
    return _enemyPaths[_rand.nextInt(_enemyPaths.length)];
  }

  /// 🚀 在地图像素范围内随机
  Vector2 _randomValidPixelPos() {
    final rand = Random();
    final x = rand.nextDouble() * cols * tileSize;
    final y = rand.nextDouble() * rows * tileSize;
    return Vector2(x, y);
  }
}

class HuanyueEnemyComponent extends SpriteComponent with CollisionCallbacks, HasGameReference {
  final String id;
  final int floor;
  final bool isBoss;
  late final int atk;
  late final int def;
  late final int hp;
  late final int reward;

  bool _isChasing = false;
  bool _isFacingLeft = true;
  Vector2? _patrolTarget;
  double _saveTimer = 0;

  late TextComponent powerText;

  HuanyueEnemyComponent({
    required this.id,
    required this.floor,
    required this.isBoss,
    required super.sprite,
    required super.position,
    required super.size,
    super.priority,
  }) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    final factor = isBoss ? 2.0 : 1.0;
    hp = (50 * pow(1.1, floor) * factor).toInt();
    atk = (10 * pow(1.1, floor) * factor).toInt();
    def = (5 * pow(1.1, floor) * factor).toInt();
    reward = (10 * pow(1.1, floor) * factor).toInt();

    final power = PlayerStorage.calculatePower(hp: hp, atk: atk, def: def);

    powerText = TextComponent(
      text: '$power',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    )..anchor = Anchor.bottomCenter;

    parent?.parent?.add(powerText);

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    powerText.position = position - Vector2(0, size.y / 2 + 4);

    final player = parent?.parent?.descendants().whereType<HuanyuePlayerComponent>().firstOrNull;

    if (player != null) {
      final distance = (player.position - position).length;

      if (distance <= 150) {
        _isChasing = true;
        _moveTowards(player.position, dt, 40);
      } else {
        _isChasing = false;
        _patrol(dt);
      }
    } else {
      _isChasing = false;
      _patrol(dt);
    }

    _saveTimer += dt;
    if (_saveTimer >= 1.0) {
      _saveTimer = 0;
      HuanyueStorage.saveEnemyPosition(id, position);
    }

    _handleMonsterCollisions();
  }

  void _moveTowards(Vector2 target, double dt, double speed) {
    final dir = (target - position).normalized();
    position += dir * speed * dt;

    final shouldFaceLeft = (target.x - position.x) < 0;
    if (shouldFaceLeft != _isFacingLeft) {
      scale.x = shouldFaceLeft ? 1 : -1;
      _isFacingLeft = shouldFaceLeft;
    }

    final mapLayer = parent?.parent as PositionComponent?;
    final mapWidth = mapLayer?.size.x ?? 99999;
    final mapHeight = mapLayer?.size.y ?? 99999;

    position.x = position.x.clamp(0, mapWidth);
    position.y = position.y.clamp(0, mapHeight);
  }

  void _patrol(double dt) {
    final mapLayer = parent?.parent as PositionComponent?;
    final mapWidth = mapLayer?.size.x ?? 99999;
    final mapHeight = mapLayer?.size.y ?? 99999;

    if (_patrolTarget == null || (position - _patrolTarget!).length < 5) {
      final rand = Random();
      const double margin = 20;
      _patrolTarget = Vector2(
        margin + rand.nextDouble() * (mapWidth - margin * 2),
        margin + rand.nextDouble() * (mapHeight - margin * 2),
      );
    }

    _moveTowards(_patrolTarget!, dt, 20);
  }

  int get spiritStoneReward => reward;

  @override
  void onRemove() {
    powerText.removeFromParent();
    super.onRemove();
  }

  void _handleMonsterCollisions() {
    if (_isChasing) return;

    final others = parent?.parent?.descendants().whereType<HuanyueEnemyComponent>();
    if (others == null) return;

    for (final other in others) {
      if (identical(this, other)) continue;

      final minDist = (size.x + other.size.x) / 2 - 2;
      final dir = position - other.position;
      final dist = dir.length;
      if (dist < minDist && dist > 0.01) {
        final push = (minDist - dist) / 2;
        final move = dir.normalized() * push;
        position += move;
        other.position -= move;
      }
    }
  }
}
