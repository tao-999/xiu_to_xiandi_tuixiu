// 📂 lib/widgets/components/huanyue_chest_spawner.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

import '../../services/resources_storage.dart';

class HuanyueChestSpawner extends Component {
  final List<List<int>> grid;
  final double tileSize;
  final int currentFloor;
  final TileManager tileManager;

  HuanyueChestSpawner({
    required this.grid,
    required this.tileSize,
    required this.currentFloor,
    required this.tileManager,
  });

  @override
  Future<void> onLoad() async {
    if (currentFloor % 5 != 0) return;

    final savedPos = await HuanyueStorage.getChestPosition(currentFloor);
    Vector2? chestGrid;

    if (savedPos != null) {
      chestGrid = savedPos;
    } else {
      final rows = grid.length;
      final cols = grid[0].length;
      final validTiles = <Vector2>[];

      for (int y = 1; y < rows - 3; y++) {
        for (int x = 1; x < cols - 3; x++) {
          bool canPlace = true;
          for (int dx = 0; dx < 2; dx++) {
            for (int dy = 0; dy < 2; dy++) {
              final tx = x + dx;
              final ty = y + dy;
              final tile = Vector2(tx.toDouble(), ty.toDouble());
              if (grid[ty][tx] != 1 || tileManager.isTileOccupied(tx, ty)) {
                canPlace = false;
                break;
              }
            }
            if (!canPlace) break;
          }
          if (canPlace) {
            validTiles.add(Vector2(x.toDouble(), y.toDouble()));
          }
        }
      }

      if (validTiles.isEmpty) return;
      validTiles.shuffle(Random());
      chestGrid = validTiles.removeLast();
      await HuanyueStorage.setChestPosition(currentFloor, chestGrid);
    }

    final chestId = '${currentFloor}_${chestGrid.x.toInt()}_${chestGrid.y.toInt()}';
    final isOpened = await HuanyueStorage.isChestOpened(chestId);
    if (isOpened) return;

    tileManager.occupy(
      chestGrid.x.toInt(),
      chestGrid.y.toInt(),
      2,
      2,
    );

    final chestSprite = await Sprite.load('migong_baoxiang.png');
    final chestOpenSprite = await Sprite.load('migong_baoxiang_open.png');

    final chest = _HuanyueChestComponent(
      id: chestId,
      closedSprite: chestSprite,
      openSprite: chestOpenSprite,
      position: chestGrid * tileSize + Vector2.all(tileSize),
      currentFloor: currentFloor,
    );

    add(chest);
  }
}

class _HuanyueChestComponent extends SpriteComponent with CollisionCallbacks {
  final String id;
  final Sprite openSprite;
  final int currentFloor;
  bool opened = false;

  _HuanyueChestComponent({
    required this.id,
    required Sprite closedSprite,
    required this.openSprite,
    required Vector2 position,
    required this.currentFloor,
  }) : super(
    sprite: closedSprite,
    size: Vector2.all(64),
    position: position,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);

    if (!opened && other.priority == 999) {
      sprite = openSprite;
      opened = true;

      HuanyueStorage.markChestOpened(id);

      final isAptitudeReward = ((currentFloor ~/ 5) % 2 == 1);
      final rewardKey = isAptitudeReward ? 'fateRecruitCharm' : 'recruitTicket';
      final rewardTextStr = isAptitudeReward ? '资质提升券 x1' : '招募券 x1';

      // ✅ 使用独立资源系统发奖励
      ResourcesStorage.add(rewardKey, BigInt.one).then((_) async {
        final snapshot = await ResourcesStorage.load();
        print('📦 奖励后资源快照：${snapshot.toMap()}');
      });

      // ✅ 飘字特效
      final rewardText = TextComponent(
        text: '🎁 $rewardTextStr',
        anchor: Anchor.bottomCenter,
        position: position - Vector2(0, size.y / 2 + 8),
        priority: 999,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 14,
          ),
        ),
      );

      rewardText.add(
        MoveEffect.by(
          Vector2(0, -40),
          EffectController(duration: 1.5, curve: Curves.easeOut),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        rewardText.removeFromParent();
      });

      parent?.add(rewardText);
    }
  }
}