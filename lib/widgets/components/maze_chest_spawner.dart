import 'dart:math';
import 'dart:ui';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:xiu_to_xiandi_tuixiu/services/maze_storage.dart';

final _uuid = Uuid(); // ✅ 全局 UUID 生成器

class MazeChestSpawner extends Component {
  final List<List<int>> grid;
  final double tileSize;
  final Set<Vector2> excluded;
  final int currentFloor;

  MazeChestSpawner({
    required this.grid,
    required this.tileSize,
    required this.currentFloor,
    this.excluded = const {},
  });

  @override
  Future<void> onLoad() async {
    if (currentFloor % 5 != 0) return;

    final savedPos = await MazeStorage.getChestPosition();

    Vector2? chestGrid;

    if (savedPos != null) {
      chestGrid = savedPos;
    } else {
      // 随机生成位置
      final rows = grid.length;
      final cols = grid[0].length;

      final validTiles = <Vector2>[];
      for (int y = 1; y < rows - 1; y++) {
        for (int x = 1; x < cols - 1; x++) {
          final tile = Vector2(x.toDouble(), y.toDouble());
          if (grid[y][x] == 1 && !excluded.contains(tile)) {
            validTiles.add(tile);
          }
        }
      }

      if (validTiles.isEmpty) return;
      validTiles.shuffle(Random());
      chestGrid = validTiles.removeLast();

      await MazeStorage.setChestPosition(chestGrid);
    }

    // ✅ 此时位置已定，生成 ID
    final chestId = '${currentFloor}_${chestGrid.x.toInt()}_${chestGrid.y.toInt()}';
    final isOpened = await MazeStorage.isChestOpened(chestId);
    if (isOpened) return;

    final chestSprite = await Sprite.load('migong_baoxiang.png');
    final chestOpenSprite = await Sprite.load('migong_baoxiang_open.png');

    final chest = _InternalChestComponent(
      id: chestId, // ✅ 现在可以传 ID 了
      closedSprite: chestSprite,
      openSprite: chestOpenSprite,
      position: chestGrid * tileSize + Vector2.all(tileSize / 2),
      currentFloor: currentFloor,
    );

    add(chest);
  }
}

class _InternalChestComponent extends SpriteComponent with CollisionCallbacks {
  final String id; // ✅ 唯一 ID
  final Sprite openSprite;
  final int currentFloor;
  bool opened = false;

  _InternalChestComponent({
    required this.id,
    required Sprite closedSprite,
    required this.openSprite,
    required Vector2 position,
    required this.currentFloor,
  }) : super(
    sprite: closedSprite,
    size: Vector2.all(48),
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

      // ✅ 后续要替换为 MazeStorage.setChestOpenedById(id)
      MazeStorage.markChestOpened(id);

      final isAptitudeReward = ((currentFloor ~/ 5) % 2 == 1);
      final reward = isAptitudeReward ? '资质提升券 x1' : '招募券 x1';

      print('🎁 第 $currentFloor 层宝箱开启，获得：$reward');

      final rewardText = TextComponent(
        text: '🎁 $reward',
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

// 加个动画效果，向上飘
      rewardText.add(
        MoveEffect.by(
          Vector2(0, -40),
          EffectController(duration: 1.5, curve: Curves.easeOut),
        ),
      );

// 自动移除
      Future.delayed(const Duration(milliseconds: 1500), () {
        rewardText.removeFromParent();
      });

      parent?.add(rewardText);
    }
  }
}
