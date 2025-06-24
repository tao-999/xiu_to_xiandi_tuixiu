import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import '../../services/global_event_bus.dart';
import '../../services/resources_storage.dart';
import '../../utils/number_format.dart';
import '../../utils/player_sprite_util.dart';
import '../../utils/tile_manager.dart';
import 'huanyue_enemy_spawner.dart';
import 'huanyue_door_component.dart';

class HuanyuePlayerComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  final double tileSize;
  final Vector2 doorPosition;
  final int currentFloor;
  final TileManager tileManager;

  Vector2? _target;
  int playerPower = 1;
  bool _isFacingLeft = false;
  bool hasTriggeredEnter = false;
  bool hintCooldown = false;

  final VoidCallback? onEnterDoor;

  late TextComponent powerText;
  late final Future<void> Function() _onPowerUpdate;

  double get _currentMoveSpeed => 200 + currentFloor * 0.1;

  HuanyuePlayerComponent({
    required this.tileSize,
    required Vector2 position,
    required this.doorPosition,
    required this.currentFloor,
    required this.tileManager,
    this.onEnterDoor,
  }) : super(
    position: position,
    anchor: Anchor.center,
    priority: 999,
  );

  @override
  Future<void> onLoad() async {
    final multiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(tileSize * multiplier);

    final player = await PlayerStorage.getPlayer();
    if (player == null) return; // ✅ 空值保护

    final gender = player.gender;
    final playerId = player.id;

    final imageName = await getEquippedSpritePath(gender, playerId);
    sprite = await game.loadSprite(imageName);

    add(RectangleHitbox());

    powerText = TextComponent(
      text: '加载中...',
      anchor: Anchor.bottomCenter,
      position: position - Vector2(0, size.y / 2 + 4),
      priority: 998,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
      ),
    );
    parent?.add(powerText);

    _onPowerUpdate = () async {
      final player = await PlayerStorage.getPlayer();
      if (player == null || PlayerStorage.getHp(player) == 0) return;

      playerPower = PlayerStorage.getPower(player);
      powerText.text = formatAnyNumber(playerPower);
      powerText.add(
        ScaleEffect.by(
          Vector2(1.3, 1.3),
          EffectController(duration: 0.15, reverseDuration: 0.15),
        ),
      );
    };

    EventBus.on('powerUpdated', _onPowerUpdate);
    Future.microtask(() async => await _onPowerUpdate());
  }

  void moveTo(Vector2 destination) {
    _target = destination;

    final dx = _target!.x - position.x;
    final shouldFaceLeft = dx < 0;
    if (shouldFaceLeft != _isFacingLeft) {
      flipHorizontally();
      _isFacingLeft = shouldFaceLeft;
    }
  }

  @override
  Future<void> update(double dt) async {
    super.update(dt);

    if (_target != null) {
      final dir = _target! - position;
      final distance = dir.length;
      final move = dir.normalized() * _currentMoveSpeed * dt;

      if (move.length >= distance) {
        position = _target!;
        _target = null;
        await HuanyueStorage.savePlayerPosition(position);
      } else {
        position += move;
      }

      powerText.position = position - Vector2(0, size.y / 2 + 4);
    }
  }

  @override
  void onRemove() {
    EventBus.off('powerUpdated', _onPowerUpdate);
    super.onRemove();
  }

  @override
  Future<void> onCollision(
      Set<Vector2> intersectionPoints, PositionComponent other) async {
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

  bool get isMoving => _target != null;
}
