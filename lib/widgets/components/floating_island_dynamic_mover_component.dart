import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:async' as dart_async;

import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_player_component.dart';
import 'hp_bar_wrapper.dart';

class FloatingIslandDynamicMoverComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  Vector2 logicalPosition;
  Vector2 targetPosition;
  final Rect movementBounds;
  double speed;
  double collisionCooldown = 0.0;
  double tauntCooldown = 0.0;

  final String? spritePath;
  final dynamic spawner;
  final double dynamicTileSize;
  final bool defaultFacingRight;
  final double minDistance;
  final double maxDistance;
  final bool enableMirror;

  final String? type;
  final String? labelText;
  final double? labelFontSize;
  final Color? labelColor;

  void Function(Set<Vector2> points, PositionComponent other)? onCustomCollision;
  TextComponent? label;

  bool isMoveLocked = false;
  Vector2? _externalTarget;
  VoidCallback? onRemoveCallback;

  double? hp;
  double currentHp = 0;
  double? atk;
  double? def;
  bool isDead = false;

  HpBarWrapper? hpBar;

  final bool enableAutoChase;
  final double? autoChaseRange;
  final String spawnedTileKey;
  final int? customPriority;

  final bool ignoreTerrainInMove; // 是否忽略地形限制移动
  dart_async.Timer? _targetTimer;

  // === 保留占位（当前策略不再搬家）===
  int _relocateFailCount = 0;
  int _relocateGraceFrames = 0;

  // === 停机/恢复 控制 ===
  bool _stoppedByIllegal = false;    // 由非法地形停机
  double _resumeCooldown = 0.0;      // 手动恢复防抖（保留）
  double _autoResumeCooldown = 0.0;  // 自动检测冷却
  static const double _autoResumeCheckInterval = 0.5; // 每0.5s检测一次

  FloatingIslandDynamicMoverComponent({
    required this.dynamicTileSize,
    required this.spawnedTileKey,
    this.type,
    this.spawner,
    required Sprite sprite,
    required Vector2 position,
    Vector2? size,
    this.speed = 30,
    required this.movementBounds,
    this.spritePath,
    required this.defaultFacingRight,
    this.minDistance = 500.0,
    this.maxDistance = 2000.0,
    this.labelText,
    this.labelFontSize,
    this.labelColor,
    this.hp = 100,
    this.atk = 10,
    this.def = 5,
    this.enableAutoChase = false,
    this.autoChaseRange,
    this.enableMirror = true,
    this.customPriority,
    this.ignoreTerrainInMove = false,
  })  : logicalPosition = position.clone(),
        targetPosition = position.clone(),
        super(
        sprite: sprite,
        size: size ?? Vector2.all(48),
        anchor: Anchor.bottomCenter,
        priority: customPriority ?? 11,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    currentHp = hp ?? 100;

    // 延迟添加碰撞盒，避免出生即碰撞
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!isDead && !isRemoving) {
        add(RectangleHitbox()..collisionType = CollisionType.active);
      }
    });

    // 名字标签
    if (labelText != null && labelText!.isNotEmpty) {
      label = TextComponent(
        text: labelText!,
        anchor: Anchor.bottomCenter,
        position: position - Vector2(0, size.y + 4),
        priority: 9999,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: labelFontSize ?? 12,
            color: labelColor ?? Colors.white,
          ),
        ),
      );
      parent?.add(label!);
    }

    // 血条
    if (hp != null && atk != null && def != null) {
      hpBar = HpBarWrapper()
        ..anchor = Anchor.bottomCenter
        ..position = position - Vector2(0, size.y + 24)
        ..priority = 9998;
      parent?.add(hpBar!);

      Future.delayed(Duration.zero, () {
        hpBar?.setStats(
          currentHp: currentHp.toInt(),
          maxHp: hp!.toInt(),
          atk: atk!.toInt(),
          def: def!.toInt(),
        );
      });
    }

    // 初始化移动目标 + 开计时器
    pickNewTarget();
    _startTargetTimer();
  }

  @override
  void onRemove() {
    onRemoveCallback?.call();
    _cancelTargetTimer();
    super.onRemove();
  }

  // ========== 计时器 ==========
  void _startTargetTimer() {
    _cancelTargetTimer();
    _targetTimer = dart_async.Timer.periodic(
      const Duration(minutes: 1),
          (_) {
        if (!isDead && !isMoveLocked && _externalTarget == null) {
          pickNewTarget();
        }
      },
    );
  }

  void _cancelTargetTimer() {
    if (_targetTimer != null && _targetTimer!.isActive) {
      _targetTimer!.cancel();
    }
    _targetTimer = null;
  }

  // ========== 停机 / 恢复 ==========
  void _stopMovement() {
    if (_stoppedByIllegal) return; // 已停过就别重复
    isMoveLocked = true;
    _stoppedByIllegal = true;      // 标记非法停机
    _externalTarget = null;
    targetPosition = logicalPosition.clone();
    _cancelTargetTimer();
    print('🛑 [Mover] 非法/未知地形 → 停止运动（tile=$spawnedTileKey）');
  }

  // 自动恢复：当前地形合法就恢复（不依赖玩家碰撞）
  void _autoResumeIfLegal() {
    if (ignoreTerrainInMove) return;
    if (spawner is! FloatingIslandDynamicSpawnerComponent) return;
    if (!_stoppedByIllegal) return;        // 不是非法停机，无需自检
    if (!isMoveLocked) return;             // 没锁也不需要

    final currentTerrain = spawner.getTerrainType(logicalPosition);
    final isLegal = currentTerrain != 'unknown' &&
        spawner.allowedTerrains.contains(currentTerrain);

    if (isLegal) {
      _resumeFromIllegal();
    }
  }

  // 实际恢复动作
  void _resumeFromIllegal() {
    _relocateFailCount = 0;
    _relocateGraceFrames = 0;
    _stoppedByIllegal = false;
    isMoveLocked = false;
    pickNewTarget();
    _startTargetTimer();
    print('▶️ [Mover] 地形已合法，自动恢复（tile=$spawnedTileKey）');
  }

  /// 若你仍然需要外部手动触发（保留接口）
  void resumeMovement() {
    if (isDead) return;
    if (!_stoppedByIllegal) return;
    if (_resumeCooldown > 0) return; // 防抖
    _resumeFromIllegal();
    _resumeCooldown = 0.25;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    // 冷却
    if (_resumeCooldown > 0) {
      _resumeCooldown -= dt;
      if (_resumeCooldown < 0) _resumeCooldown = 0;
    }
    if (_autoResumeCooldown > 0) {
      _autoResumeCooldown -= dt;
      if (_autoResumeCooldown < 0) _autoResumeCooldown = 0;
    }

    if (tauntCooldown > 0) {
      tauntCooldown -= dt;
      if (tauntCooldown < 0) tauntCooldown = 0;
    }

    // 🚫 非法/未知地形 → 立停（只停一次）
    if (!ignoreTerrainInMove && spawner is FloatingIslandDynamicSpawnerComponent) {
      if (!_stoppedByIllegal) {
        final currentTerrain = spawner.getTerrainType(logicalPosition);
        final isIllegal = (currentTerrain == 'unknown') ||
            !spawner.allowedTerrains.contains(currentTerrain);
        if (isIllegal) {
          _stopMovement();
          return;
        }
      } else {
        // 已停机 → 周期性自检，合法则自动恢复
        if (_autoResumeCooldown <= 0) {
          _autoResumeCooldown = _autoResumeCheckInterval;
          _autoResumeIfLegal();
        }
      }
    }

    // 若已停机，不再执行后续移动
    if (isMoveLocked) return;

    // ====== 自动追击 ======
    if (enableAutoChase && autoChaseRange != null) {
      final player = game.descendants().whereType<FloatingIslandPlayerComponent>().firstOrNull;
      if (player != null) {
        final delta = player.logicalPosition - logicalPosition;
        final distance = delta.length;

        if (distance <= autoChaseRange!) {
          final moveStep = delta.normalized() * speed * dt;
          final nextPos = logicalPosition + moveStep;

          if (spawner is FloatingIslandDynamicSpawnerComponent) {
            final nextTerrain = spawner.getTerrainType(nextPos);
            if (!spawner.allowedTerrains.contains(nextTerrain)) {
              pickNewTarget();
              return;
            }
          }

          logicalPosition = nextPos;
          if (enableMirror) {
            scale.x = delta.x < 0 ? -1 : 1;
          }
          return;
        }
      }
    }

    // ====== 外部控制移动 ======
    if (_externalTarget != null) {
      final delta = _externalTarget! - logicalPosition;
      final distance = delta.length;
      if (distance < 2) {
        logicalPosition = _externalTarget!;
        _externalTarget = null;
        isMoveLocked = false;
      } else {
        final moveStep = delta.normalized() * speed * dt;
        final nextPos = logicalPosition + moveStep;

        if (!ignoreTerrainInMove && spawner is FloatingIslandDynamicSpawnerComponent) {
          final nextTerrain = spawner.getTerrainType(nextPos);
          if (!spawner.allowedTerrains.contains(nextTerrain)) {
            pickNewTarget();
            _externalTarget = null;
            isMoveLocked = false;
            return;
          }
        }

        logicalPosition = nextPos;
        if (enableMirror) {
          scale.x = delta.x < 0 ? -1 : 1;
        }
      }
      return;
    }

    // ====== 普通游走 ======
    final dir = targetPosition - logicalPosition;
    final distance = dir.length;

    if (distance < 1e-3) {
      pickNewTarget();
      return;
    }

    final moveVec = dir.normalized() * speed * dt;
    final nextPos = logicalPosition + moveVec;

    if (moveVec.length >= distance) {
      logicalPosition = targetPosition.clone();
      pickNewTarget();
      return;
    }

    if (!ignoreTerrainInMove && spawner is FloatingIslandDynamicSpawnerComponent) {
      final nextTerrain = spawner.getTerrainType(nextPos);
      if (!spawner.allowedTerrains.contains(nextTerrain)) {
        final goingRight = dir.x > 0;
        pickNewTarget(preferRight: !goingRight);
        return;
      }
    }

    final actualSpeed = dt > 0 ? moveVec.length / dt : 0;
    if (actualSpeed < 5) {
      pickNewTarget();
      return;
    }

    logicalPosition = nextPos;

    final minX = movementBounds.left + size.x / 2;
    final maxX = movementBounds.right - size.x / 2;
    final minY = movementBounds.top + size.y / 2;
    final maxY = movementBounds.bottom - size.y / 2;

    if (minX <= maxX) {
      logicalPosition.x = logicalPosition.x.clamp(minX, maxX);
    }
    if (minY <= maxY) {
      logicalPosition.y = logicalPosition.y.clamp(minY, maxY);
    }
  }

  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
    label?.position = position - Vector2(0, size.y + 4);
    hpBar?.position = position - Vector2(0, size.y + 24);
  }

  void pickNewTarget({bool? preferRight}) {
    final rand = Random();
    Vector2 dir;
    do {
      dir = Vector2(rand.nextDouble() * 2 - 1, rand.nextDouble() * 2 - 1);
      if (preferRight != null) {
        if (preferRight && dir.x < 0) dir.x = dir.x.abs();
        if (!preferRight && dir.x > 0) dir.x = -dir.x.abs();
      }
    } while (dir.length < 0.1);

    dir.normalize();
    final distance = minDistance + rand.nextDouble() * (maxDistance - minDistance);
    targetPosition = logicalPosition + dir * distance;

    if (enableMirror) {
      scale.x = (targetPosition.x > logicalPosition.x) == defaultFacingRight ? 1 : -1;
    }
  }

  /// 外部设置强制目标点（打断游走）
  void moveToTarget(Vector2 target) {
    _externalTarget = target.clone();
    isMoveLocked = false;
    print('🎯 [Mover] 设置追击目标 = $_externalTarget');
  }

  // 不再依赖玩家碰撞恢复
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (isDead) return;

    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
      return;
    }

    super.onCollisionStart(points, other);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (isDead) return;

    if (onCustomCollision != null) {
      onCustomCollision!(points, other);
      return;
    }

    super.onCollision(points, other);
  }
}
