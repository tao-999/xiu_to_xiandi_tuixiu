// 📂 lib/widgets/components/zongmen_diplomacy_player_component.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;

import 'package:xiu_to_xiandi_tuixiu/models/character.dart'; // ✅ 新增：需要 Character
import '../../services/player_storage.dart';
import '../../services/role_service.dart';
import '../../services/zongmen_disciple_service.dart';
import '../../services/zongmen_storage.dart';
import '../dialogs/appoint_disciple_role_dialog.dart';
import 'zongmen_diplomacy_disciple_component.dart';
import 'zongmen_map_component.dart';

class ZongmenDiplomacyPlayerComponent extends SpriteComponent
    with HasGameReference<ZongmenMapComponent>, CollisionCallbacks {
  ZongmenDiplomacyPlayerComponent()
      : super(size: Vector2.all(48), anchor: Anchor.center);

  Vector2 logicalPosition = Vector2.zero();
  Vector2? _targetPosition;

  bool get isMoving => _targetPosition != null;
  bool _collisionEnabled = false;

  // —— 贴图路径 & 朝向 & 缓存 —— //
  late String _baseSpritePath; // 例如 icon_youli_${gender}.png（默认朝右）
  bool _facingLeft = false;
  final Map<String, Sprite> _spriteCache = {};

  // ✅ 缓存玩家对象，供 getMoveSpeed 使用
  Character? _player;

  void moveTo(Vector2 target) {
    _targetPosition = target;
    debugPrint('[DiplomacyPlayer] moveTo $target');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final player = await PlayerStorage.getPlayer();
    if (player == null) {
      debugPrint('[ZongmenDiplomacyPlayerComponent] ⚠️ Player未初始化');
      return;
    }
    _player = player; // ✅ 缓存

    // 初始贴图（默认朝右）
    _baseSpritePath = 'icon_youli_${player.gender}.png';
    await _applySpriteForFacing(left: false, keepSize: false);

    await Future.delayed(Duration.zero);

    // 避免初始与弟子重叠
    final overlappingDisciple = game.children
        .whereType<ZongmenDiplomacyDiscipleComponent>()
        .firstWhereOrNull(
          (c) => (c.logicalPosition - logicalPosition).length < 48,
    );
    if (overlappingDisciple != null) {
      logicalPosition += Vector2(0, 64);
    }
    position = logicalPosition.clone();

    Future.microtask(() {
      add(RectangleHitbox(
        anchor: Anchor.topLeft,
        collisionType: CollisionType.active,
      ));
      _collisionEnabled = true;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_targetPosition != null && _player != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;

      // ✅ 同步取速度（带 Character 参数）
      final moveStep = PlayerStorage.getMoveSpeed(_player!) * dt;

      if (distance <= moveStep) {
        logicalPosition = _targetPosition!;
        _targetPosition = null;
      } else {
        logicalPosition += delta.normalized() * moveStep;
      }

      // ✅ 按水平分量切换方向贴图（_left），不再用镜像
      final nowFacingLeft = delta.x < 0;
      if (nowFacingLeft != _facingLeft) {
        _facingLeft = nowFacingLeft;
        _applySpriteForFacing(left: _facingLeft, keepSize: true);
      }
    }

    position = logicalPosition.clone();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    final mapGame = game as ZongmenMapComponent;
    if (!_collisionEnabled || mapGame.isDragging) return;
    if (other is! ZongmenDiplomacyDiscipleComponent) return;

    _targetPosition = null;
    final offset = (logicalPosition - other.logicalPosition).normalized() * 15;
    logicalPosition += offset;
    position = logicalPosition.clone();

    game.pauseEngine();

    void resumeIfNeeded() {
      if (game.paused) game.resumeEngine();
    }

    final d = other.disciple;
    final displayRealm =
    ZongmenDiscipleService.getRealmNameByLevel(d.realmLevel);

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

  // ===== 内部：贴图加载/缓存（与浮空岛玩家一致） =====
  Future<void> _applySpriteForFacing({
    required bool left,
    required bool keepSize,
  }) async {
    final path = left ? _withLeftSuffix(_baseSpritePath) : _baseSpritePath;
    final loaded = await _loadSpriteCached(path);
    if (!keepSize && loaded != null) {
      final original = loaded.srcSize;
      const fixedW = 48.0;
      final scaledH = original.y * (fixedW / original.x);
      size = Vector2(fixedW, scaledH);
    }
  }

  Future<Sprite?> _loadSpriteCached(String path) async {
    if (_spriteCache.containsKey(path)) {
      sprite = _spriteCache[path];
      return sprite;
    }
    try {
      final sp = await Sprite.load(path);
      _spriteCache[path] = sp;
      sprite = sp;
      return sp;
    } catch (e) {
      if (path != _baseSpritePath) {
        debugPrint('⚠️ 加载 $path 失败，回退到 $_baseSpritePath；err=$e');
        return _loadSpriteCached(_baseSpritePath);
      } else {
        debugPrint('❌ 基础贴图 $_baseSpritePath 加载失败；err=$e');
        return null;
      }
    }
  }

  String _withLeftSuffix(String basePath) {
    if (basePath.endsWith('.png')) {
      final i = basePath.lastIndexOf('.png');
      return '${basePath.substring(0, i)}_left.png';
    }
    return '${basePath}_left';
  }
}
