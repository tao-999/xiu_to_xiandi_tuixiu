import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // ✅ 引入 uuid
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/maze_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/maze_utils.dart';

final _uuid = Uuid(); // ✅ 全局只生成一次

class RewardTagComponent extends Component {
  final int reward;
  final String enemyId; // ✅ 添加唯一ID

  RewardTagComponent(this.reward, this.enemyId);
}

class EnemySpawner extends Component with HasGameRef {
  final List<List<int>> grid;
  final double tileSize;
  final Set<Vector2> excluded;
  final int currentFloor;

  EnemySpawner({
    required this.grid,
    required this.tileSize,
    required this.currentFloor,
    this.excluded = const {},
  });

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

  final double minDistance = 1.5;

  @override
  Future<void> onLoad() async {
    final rand = Random();

    final player = await PlayerStorage.getPlayer();
    final playerPower = player?.power ?? 0;

    final killedEnemies = await MazeStorage.getKilledEnemyIds(); // ✅ 改为 ID 模式
    final savedEnemies = await MazeStorage.loadEnemyStates();

    final reachable = getReachableTiles(grid: grid, start: excluded.first);

    if (savedEnemies != null && savedEnemies.isNotEmpty) {
      for (final e in savedEnemies) {
        if (killedEnemies.contains(e.id)) continue;

        final tile = Vector2(e.x, e.y);
        if (!reachable.contains(tile)) continue;

        final sprite = await gameRef.loadSprite(e.spritePath);

        final enemy = SpriteComponent(
          sprite: sprite,
          position: tile * tileSize + Vector2.all(tileSize / 2),
          size: Vector2.all(tileSize * (e.isBoss ? 2 : 1)),
          anchor: Anchor.center,
          priority: 800,
        );

        final power = (e.hp * 0.4 + e.atk * 2 + e.def * 1.5).toInt();
        final isStronger = power > playerPower;

        final label = TextComponent(
          text: '$power',
          anchor: Anchor.bottomCenter,
          position: Vector2(tileSize / 2, -4),
          scale: Vector2.all(0.7),
          priority: 801,
          textRenderer: TextPaint(
            style: TextStyle(
              color: isStronger ? Colors.red : Colors.green,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        if (e.isBoss) {
          final crown = TextComponent(
            text: '👑',
            anchor: Anchor.topCenter,
            position: Vector2(tileSize / 2, -tileSize / 1.2),
            priority: 802,
            scale: Vector2.all(1.2),
          );
          enemy.add(crown);
        }

        enemy.add(RectangleHitbox());
        enemy.add(label);
        enemy.add(RewardTagComponent(e.reward, e.id)); // ✅ 绑定 ID
        add(enemy);
      }
      return;
    }

    final availableTiles = reachable.where((tile) => !excluded.contains(tile)).toList();
    availableTiles.shuffle(rand);

    final spawnCount = min(_enemyPaths.length, availableTiles.length);
    final spawnTiles = availableTiles.take(spawnCount).toList();
    print('🗺️ 怪物生成坐标：');
    for (final tile in spawnTiles) {
      print('  - (${tile.x}, ${tile.y})');
    }

    if (spawnTiles.isEmpty) return;

    final Vector2 entry = excluded.firstWhere((e) => e != null, orElse: () => Vector2.zero());
    spawnTiles.sort((a, b) => b.distanceToSquared(entry).compareTo(a.distanceToSquared(entry)));
    final bossPos = spawnTiles.first;
    print('👑 BOSS 生成于：${bossPos.x}, ${bossPos.y}');
    print('🧟‍♂️ 本层生成敌人数量：${spawnTiles.length}');

    final List<EnemyState> newEnemyStates = [];

    for (int i = 0; i < spawnTiles.length; i++) {
      final tile = spawnTiles[i];
      final isBoss = tile.distanceTo(bossPos) < 0.01;

      final enemyId = _uuid.v4();

      final baseHp = rand.nextInt(40) + 10;
      final baseAtk = rand.nextInt(9) + 1;
      final baseDef = rand.nextInt(5) + 1;

      double multiplier = pow(1.1, currentFloor - 1).toDouble();
      if (isBoss) multiplier *= 1.5;

      final hp = (baseHp * multiplier).toInt();
      final atk = (baseAtk * multiplier).toInt();
      final def = (baseDef * multiplier).toInt();
      final power = (hp * 0.4 + atk * 2 + def * 1.5).toInt();
      final isStronger = power > playerPower;

      final baseReward = isBoss ? 20 : 10;
      final reward = (baseReward * pow(1.1, currentFloor - 1)).toInt();

      final spritePath = _enemyPaths[i];
      final sprite = await gameRef.loadSprite(spritePath);

      final enemy = SpriteComponent(
        sprite: sprite,
        position: tile * tileSize + Vector2.all(tileSize / 2),
        size: Vector2.all(tileSize * (isBoss ? 2 : 1)),
        anchor: Anchor.center,
        priority: 800,
      );

      final label = TextComponent(
        text: '$power',
        anchor: Anchor.bottomCenter,
        position: Vector2(tileSize / 2, -4),
        scale: Vector2.all(0.7),
        priority: 801,
        textRenderer: TextPaint(
          style: TextStyle(
            color: isStronger ? Colors.red : Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      if (isBoss) {
        final crown = TextComponent(
          text: '👑',
          anchor: Anchor.topCenter,
          position: Vector2(tileSize / 2, -tileSize / 1.2),
          priority: 802,
          scale: Vector2.all(1.2),
        );
        enemy.add(crown);
      }

      enemy.add(RectangleHitbox());
      enemy.add(label);
      enemy.add(RewardTagComponent(reward, enemyId));
      add(enemy);

      newEnemyStates.add(EnemyState(
        id: enemyId,
        x: tile.x,
        y: tile.y,
        hp: hp,
        atk: atk,
        def: def,
        spritePath: spritePath,
        isBoss: isBoss,
        reward: reward,
      ));
    }

    await MazeStorage.saveEnemyStates(newEnemyStates);
  }
}
