import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/player_sprite_util.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_diplomacy_disciple_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_map_component.dart';
import '../../services/role_service.dart';
import '../../services/zongmen_disciple_service.dart';
import '../../services/zongmen_storage.dart';
import '../dialogs/appoint_disciple_role_dialog.dart';

class ZongmenDiplomacyPlayerComponent extends SpriteComponent
    with HasGameReference<ZongmenMapComponent>, CollisionCallbacks{
  ZongmenDiplomacyPlayerComponent()
      : super(size: Vector2.all(48), anchor: Anchor.center);

  Vector2 logicalPosition = Vector2.zero();
  Vector2? _targetPosition;
  final double moveSpeed = 160;

  bool get isMoving => _targetPosition != null;
  bool _collisionEnabled = false; // 🚫初始化阶段禁用碰撞逻辑

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

    // ✅ 检查是否与弟子重叠，避免刚出生就弹框
    await Future.delayed(Duration.zero); // 确保其他组件也加载完了

    final overlappingDisciple = game.children
        .whereType<ZongmenDiplomacyDiscipleComponent>()
        .firstWhereOrNull(
          (c) => (c.logicalPosition - logicalPosition).length < 48,
    );

    if (overlappingDisciple != null) {
      logicalPosition += Vector2(0, 64); // 往下偏移避免重叠
    }

    position = logicalPosition.clone(); // 同步视觉位置

    // ✅ 最后一帧后再添加碰撞盒，彻底防止初始化阶段触发
    Future.microtask(() {
      add(
        RectangleHitbox(
          anchor: Anchor.topLeft,
          collisionType: CollisionType.active,
        ),
      );
      _collisionEnabled = true;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

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

    position = logicalPosition.clone(); // 实时同步位置
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    final mapGame = game as ZongmenMapComponent;
    if (!_collisionEnabled || mapGame.isDragging) return;
    if (other is! ZongmenDiplomacyDiscipleComponent) return;

    // 🧨 碰撞到弟子，先弹开再弹框
    _targetPosition = null; // 💥 强制打断移动
    final offset = (logicalPosition - other.logicalPosition).normalized() * 15;
    logicalPosition += offset;
    position = logicalPosition.clone();

    game.pauseEngine();

    void resumeIfNeeded() {
      if (game.paused) game.resumeEngine();
    }

    final d = other.disciple;
    final displayRealm = ZongmenDiscipleService.getRealmNameByLevel(d.realmLevel);

    showDialog(
      context: game.buildContext!,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => AppointDiscipleRoleDialog(
        discipleName: d.name,
        currentRole: d.role,
        currentRealm: displayRealm,
        onAppointed: (newRole) async {
          resumeIfNeeded();

          final oldRole = d.role;
          d.role = newRole;

          await RoleService.updateDiscipleRoleBonus(d.id, oldRole, newRole);
          await ZongmenStorage.setDiscipleRole(d.id, newRole ?? '弟子');
        },
      ),
    ).then((_) {
      resumeIfNeeded();
    });
  }

}
