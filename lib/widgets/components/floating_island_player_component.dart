import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/player_sprite_util.dart';

class FloatingIslandPlayerComponent extends SpriteComponent with HasGameRef {
  FloatingIslandPlayerComponent({this.onPositionChanged})
      : super(size: Vector2.all(64), anchor: Anchor.center);

  Vector2? _targetPosition;
  final double moveSpeed = 160;

  final void Function(Vector2 position)? onPositionChanged;

  // 新增 StreamController 位置流
  final StreamController<Vector2> _positionStreamController = StreamController.broadcast();

  Stream<Vector2> get onPositionChangedStream => _positionStreamController.stream;

  void moveTo(Vector2 target) {
    _targetPosition = target;
  }

  @override
  Future<void> onLoad() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) {
      debugPrint('[FloatingIslandPlayerComponent] ⚠️ Player未初始化');
      return;
    }

    final path = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(path);

    // ❌ 不要再重置position
    // position = Vector2.zero();

    // 🚀 改成只在position为空时才设默认值
    if (position == Vector2.zero()) {
      onPositionChanged?.call(position);
      _positionStreamController.add(position);
    } else {
      // ✅ 这里也要通知监听器，保证地图刷新
      onPositionChanged?.call(position);
      _positionStreamController.add(position);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_targetPosition != null) {
      final delta = _targetPosition! - position;
      if (delta.length < moveSpeed * dt) {
        position = _targetPosition!;
        _targetPosition = null;
        onPositionChanged?.call(position);
        _positionStreamController.add(position);
        return;
      }

      scale = Vector2(delta.x < 0 ? -1 : 1, 1);
      position += delta.normalized() * moveSpeed * dt;
      onPositionChanged?.call(position);
      _positionStreamController.add(position);
    }
  }

  @override
  void onRemove() {
    _positionStreamController.close();
    super.onRemove();
  }

  void notifyPositionChanged() {
    print('[FloatingIslandPlayerComponent] notifyPositionChanged called with position: $position');
    onPositionChanged?.call(position);
    _positionStreamController.add(position);
  }
}
