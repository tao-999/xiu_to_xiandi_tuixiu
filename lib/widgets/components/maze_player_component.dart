import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/maze_storage.dart';
import 'enemy_spawner.dart';

class MazePlayerComponent extends SpriteComponent
    with CollisionCallbacks, HasGameRef {
  final VoidCallback onCollideWithChest;
  final List<List<int>> grid;
  final double tileSize;

  List<Vector2> _path = [];
  int _currentStep = 0;
  final double _moveSpeed = 200;
  late final int playerPower;

  MazePlayerComponent({
    required Sprite sprite,
    required this.grid,
    required this.tileSize,
    required Vector2 position,
    required this.onCollideWithChest,
  }) : super(
    sprite: sprite,
    position: position,
    size: Vector2.all(48),
    anchor: Anchor.center,
    priority: 999,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    final player = await PlayerStorage.getPlayer();
    playerPower = player?.power ?? 0;

    final Vector2? savedPos = await MazeStorage.getPlayerPosition();
    if (savedPos != null && savedPos != Vector2.zero()) {
      position = savedPos;
    }
  }

  void followPath(List<Vector2> path) {
    if (path.isEmpty) return;
    _path = path.map((p) => p * tileSize + Vector2.all(tileSize / 2)).toList();
    _currentStep = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_path.isNotEmpty && _currentStep < _path.length) {
      final target = _path[_currentStep];
      final direction = target - position;
      final distance = direction.length;
      final step = _moveSpeed * dt;

      if (distance <= step) {
        position = target;
        _currentStep++;
        if (_currentStep >= _path.length) {
          _path = [];
          MazeStorage.savePlayerPosition(position); // ✅ 保存玩家当前位置
        }
      } else {
        position += direction.normalized() * step;
      }

      if (parent is PositionComponent && gameRef.size != Vector2.zero()) {
        final screenCenter = gameRef.size / 2;
        final container = parent as PositionComponent;
        final mapSize = Vector2(grid[0].length * tileSize, grid.length * tileSize);
        final desired = screenCenter - position;

        container.position = Vector2(
          desired.x.clamp(gameRef.size.x - mapSize.x, 0),
          desired.y.clamp(gameRef.size.y - mapSize.y, 0),
        );
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) async {
    super.onCollision(intersectionPoints, other);

    // ✅ 宝箱逻辑（priority 0）
    if (other.priority == 0) {
      final chestComp = other.children.whereType<ChestIdComponent>().firstOrNull;
      if (chestComp == null) return;

      final chestId = chestComp.chestId;
      final isOpened = await MazeStorage.isChestOpened(chestId);
      if (!isOpened) {
        onCollideWithChest();
        await MazeStorage.markChestOpened(chestId);
      }
      return;
    }

    // ✅ 敌人逻辑（priority 800）
    if (other.priority == 800 && other is SpriteComponent) {
      final rewardComp = other.children.whereType<RewardTagComponent>().firstOrNull;
      if (rewardComp == null) return;

      final enemyId = rewardComp.enemyId;
      final killedIds = await MazeStorage.getKilledEnemyIds();
      if (killedIds.contains(enemyId)) return;

      final textList = other.children.whereType<TextComponent>().toList();
      final powerText = textList.firstWhere(
            (tc) => RegExp(r'^\d+$').hasMatch(tc.text),
        orElse: () => TextComponent(text: '0'),
      );

      final enemyPower = int.tryParse(powerText.text) ?? 0;
      final reward = rewardComp.reward;

      if (playerPower >= enemyPower) {
        _triggerExplosion(other.position);
        _showRewardText(reward, other.position);

        await MazeStorage.markEnemyKilledById(enemyId);
        other.removeFromParent();
        _applySpiritStoneReward(reward);
      }
    }
  }

  Future<void> _applySpiritStoneReward(int reward) async {
    final player = await PlayerStorage.getPlayer();
    if (player != null) {
      player.resources.add('spiritStoneLow', reward);
      await player.resources.saveToStorage();
    }
  }

  void _triggerExplosion(Vector2 position) {
    final explosion = CircleComponent(
      radius: 14,
      anchor: Anchor.center,
      position: position,
      paint: Paint()..color = Colors.orange,
      priority: 998,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      explosion.removeFromParent();
    });

    parent?.add(explosion);
  }

  void _showRewardText(int reward, Vector2 position) {
    final text = TextComponent(
      text: '+$reward 下品灵石',
      anchor: Anchor.bottomCenter,
      position: position - Vector2(0, 8),
      priority: 999,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    text.add(
      MoveEffect.by(
        Vector2(0, -48),
        EffectController(duration: 1.2, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      text.removeFromParent();
    });

    parent?.add(text);
  }

  Vector2 get gridPosition => Vector2(
    (position.x / tileSize).floorToDouble(),
    (position.y / tileSize).floorToDouble(),
  );

  bool get isMoving => _path.isNotEmpty;
}

class ChestIdComponent extends Component {
  final String chestId;

  ChestIdComponent(this.chestId);
}
