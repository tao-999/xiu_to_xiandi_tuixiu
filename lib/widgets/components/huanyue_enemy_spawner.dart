import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

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

class HuanyueEnemySpawner extends Component with HasGameRef {
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

    if (!await HuanyueStorage.isEnemyKilled(bossId)) {
      tileManager.occupy(bossTile.x.toInt(), bossTile.y.toInt(), 4, 4);

      final bossSprite = await Sprite.load(_randomEnemyPath());
      add(HuanyueEnemyComponent(
        id: bossId,
        floor: floor,
        isBoss: true,
        sprite: bossSprite,
        position: bossTile * tileSize + Vector2.all(tileSize),
        size: Vector2.all(tileSize * 4),
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

      tileManager.occupy(pos.x.toInt(), pos.y.toInt(), 2, 2);

      final sprite = await Sprite.load(_randomEnemyPath());
      add(HuanyueEnemyComponent(
        id: id,
        floor: floor,
        isBoss: false,
        sprite: sprite,
        position: pos * tileSize + Vector2.all(tileSize),
        size: Vector2.all(tileSize * 2),
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

class HuanyueEnemyComponent extends SpriteComponent with CollisionCallbacks {
  final String id;
  final int floor;
  final bool isBoss;
  late final int atk;
  late final int def;
  late final int hp;
  late final int reward;

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

    add(TextComponent(
      text: '$power',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    )
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x / 2, -4));

    add(RectangleHitbox()..collisionType = CollisionType.passive);

  }

  int get spiritStoneReward => reward;
}