import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/player_sprite_util.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';

class ZongmenDiplomacyPlayerComponent extends SpriteComponent
    with HasGameReference<FlameGame>, CollisionCallbacks {
  ZongmenDiplomacyPlayerComponent()
      : super(size: Vector2.all(32), anchor: Anchor.center);

  /// 🚀逻辑世界坐标
  Vector2 logicalPosition = Vector2.zero();

  /// 🚀移动目标
  Vector2? _targetPosition;

  /// 🚀移动速度
  final double moveSpeed = 160;

  /// 🚀是否正在移动
  bool get isMoving => _targetPosition != null;

  /// 🚀设置移动目标
  void moveTo(Vector2 target) {
    _targetPosition = target;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final player = await PlayerStorage.getPlayer();
    if (player == null) {
      debugPrint('[ZongmenDiplomacyPlayerComponent] ⚠️ Player未初始化');
      return;
    }

    final path = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(path);

    // 添加矩形碰撞盒
    add(
      RectangleHitbox(
        anchor: Anchor.topLeft,
        collisionType: CollisionType.active,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 🚀移动逻辑
    if (_targetPosition != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;
      final moveStep = moveSpeed * dt;

      if (distance <= moveStep) {
        logicalPosition = _targetPosition!;
        _targetPosition = null;
      } else {
        logicalPosition += delta.normalized() * moveStep;
      }

      // 翻转
      if (delta.x.abs() > 1e-3) {
        scale = Vector2(delta.x < 0 ? -1 : 1, 1);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is SectComponent) {
      debugPrint('[碰撞] 角色碰到了宗门圆圈：${other.info.name}');

      // 🚀先把角色移到圈外
      final Vector2 delta = logicalPosition - other.worldPosition;
      final Vector2 safeDirection = delta.normalized();
      logicalPosition = other.worldPosition + safeDirection * (
          other.circleRadius + this.size.x / 2 + 50
      );

      // 🚀清掉移动目标
      _targetPosition = null;

      // 🚀再暂停地图
      game.pauseEngine();

      // 🚀再弹窗
      showDialog(
        context: game.buildContext!,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Color(0xFFFFF8E1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  '✨${other.info.name}\n'
                      '✨ ${other.info.level}级宗门\n'
                      '✨ ${other.info.description}',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ).then((_) {
        // 🚀只恢复地图，不再推开
        game.resumeEngine();
      });
    }
  }
}
