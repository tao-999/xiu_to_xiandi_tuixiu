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
    _rand = Random(floor); // ✅ 楼层种子，保证每层怪一致
  }

  @override
  Future<void> onLoad() async {
    print('✅ HuanyueEnemySpawner loaded (floor $floor)');

    final bossId = 'boss-floor-$floor';
    Vector2? bossTile = await HuanyueStorage.getEnemyPosition(bossId);
    if (bossTile == null) {
      bossTile = _randomValidPos(sizeInTiles: 4, spacing: 1);
      await HuanyueStorage.saveEnemyPosition(bossId, bossTile);
    }
    // 🚀 这里直接用bossTile（不管是不是新生成的）
    if (!await HuanyueStorage.isEnemyKilled(bossId)) {
      tileManager.occupy(bossTile.x.toInt(), bossTile.y.toInt(), 4, 4);

      final bossSprite = await Sprite.load(_randomEnemyPath());
      add(HuanyueEnemyComponent(
        id: bossId,
        floor: floor,
        isBoss: true,
        sprite: bossSprite,
        position: bossTile, // 这里直接存像素坐标
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
        pos = _randomValidPos(sizeInTiles: 2, spacing: 1);
        await HuanyueStorage.saveEnemyPosition(id, pos);
      }
      // 🚀 同理，用pos，不用再 * tileSize
      tileManager.occupy(pos.x.toInt(), pos.y.toInt(), 2, 2);

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

  Vector2 _randomValidPos({required int sizeInTiles, int spacing = 0}) {
    int attempts = 0;
    while (attempts < 1000) {
      final x = _rand.nextInt(cols - sizeInTiles - spacing * 2) + spacing;
      final y = _rand.nextInt(rows - sizeInTiles - spacing * 2) + spacing;

      if (x < 4 || y < 4 || x + sizeInTiles + spacing > cols - 2 || y + sizeInTiles + spacing > rows - 2) {
        attempts++;
        continue;
      }

      if (!tileManager.isOccupied(x - spacing, y - spacing, sizeInTiles + spacing * 2, sizeInTiles + spacing * 2)) {
        return Vector2(x.toDouble(), y.toDouble());
      }

      attempts++;
    }

    print('⚠️ 找不到合法怪物出生点，fallback');
    return Vector2.zero();
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
  double _saveTimer = 0; // 用于控制存储频率

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

    // ✅ 把数字挂到mapLayer（parent?.parent）
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

    // 注意这里：把数字挂到上层
    parent?.parent?.add(powerText);

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新头顶数字位置
    powerText.position = position - Vector2(0, size.y / 2 + 4);

    // 获取玩家对象（2层parent->descendants）
    final player = parent?.parent?.descendants().whereType<HuanyuePlayerComponent>().firstOrNull;

    if (player != null) {
      final distance = (player.position - position).length;

      if (distance <= 150) {
        _isChasing = true;
        _moveTowards(player.position, dt, 40); // 追击速度
      } else {
        _isChasing = false;
        _patrol(dt); // 巡逻
      }
    } else {
      _isChasing = false;
      _patrol(dt); // 没有玩家也巡逻
    }

    // 📝 每隔1秒自动持久化怪物位置（骚操作！）
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

    // 判断翻转
    final shouldFaceLeft = (target.x - position.x) < 0;
    if (shouldFaceLeft != _isFacingLeft) {
      scale.x = shouldFaceLeft ? 1 : -1;
      _isFacingLeft = shouldFaceLeft;
    }

    // 限制位置，防止跑到地图外
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

    // 没有目标 或 接近目标，就生成新目标
    if (_patrolTarget == null || (position - _patrolTarget!).length < 5) {
      final rand = Random();
      // 生成在地图内的安全目标点（边缘留 margin）
      const double margin = 20;
      _patrolTarget = Vector2(
        margin + rand.nextDouble() * (mapWidth - margin * 2),
        margin + rand.nextDouble() * (mapHeight - margin * 2),
      );
    }

    // 先移动
    _moveTowards(_patrolTarget!, dt, 20);

    // 如果撞到地图边缘，就弹回来（刷新巡逻目标点）
    const double margin = 2;
    bool bounced = false;

    // 横向
    if (position.x < margin) {
      position.x = margin;
      _patrolTarget = Vector2(
        position.x + Random().nextDouble() * 80 + 40, // 往右弹
        position.y + (Random().nextDouble() - 0.5) * 100,
      );
      bounced = true;
    } else if (position.x > mapWidth - margin) {
      position.x = mapWidth - margin;
      _patrolTarget = Vector2(
        position.x - Random().nextDouble() * 80 - 40, // 往左弹
        position.y + (Random().nextDouble() - 0.5) * 100,
      );
      bounced = true;
    }

    // 纵向
    if (position.y < margin) {
      position.y = margin;
      _patrolTarget = Vector2(
        position.x + (Random().nextDouble() - 0.5) * 100,
        position.y + Random().nextDouble() * 80 + 40, // 往下弹
      );
      bounced = true;
    } else if (position.y > mapHeight - margin) {
      position.y = mapHeight - margin;
      _patrolTarget = Vector2(
        position.x + (Random().nextDouble() - 0.5) * 100,
        position.y - Random().nextDouble() * 80 - 40, // 往上弹
      );
      bounced = true;
    }

    if (bounced) {
      // 防止弹出界后还卡住
      _patrolTarget!.clamp(
        Vector2(margin, margin),
        Vector2(mapWidth - margin, mapHeight - margin),
      );
    }
  }

  int get spiritStoneReward => reward;

  @override
  void onRemove() {
    // 确保删除数字
    powerText.removeFromParent();
    super.onRemove();
  }

  void _handleMonsterCollisions() {
    // 只在非chase时管，追击时别乱推自己
    if (_isChasing) return;

    // 遍历所有怪物，避免和自己比
    final others = parent?.parent?.descendants().whereType<HuanyueEnemyComponent>();
    if (others == null) return;

    for (final other in others) {
      if (identical(this, other)) continue;

      final minDist = (size.x + other.size.x) / 2 - 2; // -2留一点重叠
      final dir = position - other.position;
      final dist = dir.length;
      if (dist < minDist && dist > 0.01) {
        // 推开距离
        final push = (minDist - dist) / 2;
        final move = dir.normalized() * push;
        position += move;
        other.position -= move;
      }
    }
  }
}