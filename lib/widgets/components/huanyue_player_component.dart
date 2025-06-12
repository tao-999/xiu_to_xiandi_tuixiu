import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_pathfinder.dart';
import '../../services/global_event_bus.dart';
import '../../services/resources_storage.dart';
import '../../utils/number_format.dart';
import '../../utils/tile_manager.dart';
import 'huanyue_enemy_spawner.dart';
import 'huanyue_door_component.dart';

class HuanyuePlayerComponent extends SpriteComponent
    with CollisionCallbacks, HasGameRef {
  final double tileSize;
  final List<List<int>> grid;

  List<Vector2> _path = [];
  int _currentStep = 0;
  final double _moveSpeed = 200;
  int playerPower = 1;

  final VoidCallback? onEnterDoor;
  final Vector2 doorPosition;
  final int currentFloor;
  final TileManager tileManager;

  bool hasTriggeredEnter = false;
  bool hintCooldown = false;
  bool _isFacingLeft = false; // ✅ 当前朝向

  late TextComponent powerText;
  late final Future<void> Function() _onPowerUpdate;

  HuanyuePlayerComponent({
    required this.tileSize,
    required this.grid,
    required Vector2 position,
    this.onEnterDoor,
    required this.doorPosition,
    required this.currentFloor,
    required this.tileManager,
  }) : super(
    position: position,
    anchor: Anchor.center,
    priority: 999,
  );

  @override
  Future<void> onLoad() async {
    final multiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(tileSize * multiplier);

    final gender = await PlayerStorage.getField<String>('gender') ?? 'male';
    sprite = await gameRef.loadSprite(
      gender == 'female' ? 'icon_youli_female.png' : 'icon_youli_male.png',
    );
    add(RectangleHitbox());

    powerText = TextComponent(
      text: '加载中...',
      anchor: Anchor.bottomCenter,
      position: position - Vector2(0, size.y / 2 + 4),
      priority: 998,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.cyanAccent,
        ),
      ),
    );
    parent?.add(powerText);

    _onPowerUpdate = () async {
      final player = await PlayerStorage.getPlayer();
      if (player == null || PlayerStorage.getHp(player) == 0) return;

      final newPower = PlayerStorage.getPower(player);
      playerPower = newPower;
      powerText.text = formatAnyNumber(playerPower);

      powerText.add(
        ScaleEffect.by(
          Vector2(1.3, 1.3),
          EffectController(duration: 0.15, reverseDuration: 0.15),
        ),
      );
    };

    EventBus.on('powerUpdated', _onPowerUpdate);

    Future.microtask(() async {
      await _onPowerUpdate();
    });

    final gridPos = gridPosition;
    tileManager.occupy(gridPos.x.toInt(), gridPos.y.toInt(), 2, 2);
  }

  void moveTo(Vector2 destination) {
    final start = gridPosition;
    final end = Vector2(
      (destination.x ~/ tileSize).toDouble(),
      (destination.y ~/ tileSize).toDouble(),
    );

    final rawPath = HuanyuePathfinder.findPath(
      grid: grid,
      start: start,
      end: end,
    );

    if (rawPath.isNotEmpty) {
      _path = rawPath
          .map((p) => p * tileSize + Vector2.all(tileSize / 2))
          .toList();
      _currentStep = 0;
    }
  }

  @override
  void onRemove() {
    EventBus.off('powerUpdated', _onPowerUpdate);
    super.onRemove();
  }

  @override
  Future<void> update(double dt) async {
    super.update(dt);

    if (_path.isEmpty || _currentStep >= _path.length) return;

    final target = _path[_currentStep];
    final dir = target - position;
    final distance = dir.length;
    final move = dir.normalized() * _moveSpeed * dt;

    // ✅ 判断左右方向并翻转角色图像
    if (dir.x.abs() > 1e-3) {
      final shouldFaceLeft = dir.x < 0;
      if (shouldFaceLeft != _isFacingLeft) {
        flipHorizontally();
        _isFacingLeft = shouldFaceLeft;
      }
    }

    if (move.length >= distance) {
      position = target;
      _currentStep++;
      await HuanyueStorage.savePlayerPosition(position);
    } else {
      position += move;
    }

    powerText.position = position - Vector2(0, size.y / 2 + 4);
  }

  @override
  Future<void> onCollision(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) async {
    super.onCollision(intersectionPoints, other);

    if (other is HuanyueEnemyComponent) {
      final enemyPower = PlayerStorage.calculatePower(
        hp: other.hp,
        atk: other.atk,
        def: other.def,
      );

      if (playerPower >= enemyPower) {
        _triggerExplosion(other.position);
        _showRewardText('+${other.reward} 下品灵石', other.position);

        // ✅ 使用 ResourcesStorage 发奖励
        await ResourcesStorage.add('spiritStoneLow', BigInt.from(other.reward));

        HuanyueStorage.markEnemyKilled(other.id);
        other.removeFromParent();
      } else {
        _shakeOnWeak();
      }
    }

    if (other is HuanyueDoorComponent) {
      if (hasTriggeredEnter) return;

      final allEnemiesKilled =
      await HuanyueStorage.areAllEnemiesKilled(currentFloor);
      final isChestOpened =
      await HuanyueStorage.isCurrentFloorChestOpened(currentFloor);

      if (!allEnemiesKilled || !isChestOpened) {
        if (!hintCooldown) {
          hintCooldown = true;
          _showHintText('清光怪物和宝箱才能进入下一层', position);

          Future.delayed(const Duration(seconds: 1), () {
            hintCooldown = false;
          });
        }
        return;
      }

      hasTriggeredEnter = true;
      onEnterDoor?.call();
    }
  }

  void _triggerExplosion(Vector2 pos) {
    final explosion = CircleComponent(
      radius: 14,
      anchor: Anchor.center,
      position: pos,
      paint: Paint()..color = Colors.orange,
      priority: 998,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      explosion.removeFromParent();
    });

    parent?.add(explosion);
  }

  void _showRewardText(String text, Vector2 pos) {
    final component = TextComponent(
      text: text,
      anchor: Anchor.bottomCenter,
      position: pos - Vector2(0, 8),
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 14,
        ),
      ),
    );

    component.add(
      MoveEffect.by(
        Vector2(0, -48),
        EffectController(duration: 1.2, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      component.removeFromParent();
    });

    parent?.add(component);
  }

  void _showHintText(String text, Vector2 pos) {
    final hint = TextComponent(
      text: text,
      anchor: Anchor.bottomCenter,
      position: pos - Vector2(0, 8),
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );

    hint.add(
      MoveEffect.by(
        Vector2(0, -32),
        EffectController(duration: 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      hint.removeFromParent();
    });

    parent?.add(hint);
  }

  void _shakeOnWeak() {
    add(MoveEffect.by(
      Vector2(5, 0),
      EffectController(duration: 0.05, reverseDuration: 0.05, repeatCount: 3),
    ));
  }

  Vector2 get gridPosition => Vector2(
    (position.x / tileSize).floorToDouble(),
    (position.y / tileSize).floorToDouble(),
  );

  bool get isMoving => _path.isNotEmpty;
}
