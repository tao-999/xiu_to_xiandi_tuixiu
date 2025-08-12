// 📄 lib/widgets/components/floating_island_dynamic_mover_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:async' as dart_async;

import '../../services/dead_boss_storage.dart';
import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_player_component.dart';
import 'floating_text_component.dart';
import 'hp_bar_wrapper.dart';
import 'resource_bar.dart';

// ✅ 新增：Boss 奖励分发（按 boss.type 路由到各自 onKilled）
import 'package:xiu_to_xiandi_tuixiu/logic/combat/boss_reward_registry.dart';

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
  bool deathMarked = false; // ✅ 已持久化标记
  bool get _isBossType => (type?.toLowerCase().contains('boss') ?? false);

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

  // ========== 战斗：统一伤害入口 ==========
  /// ✅ 推荐使用：带上下文（击杀者/地图偏移/UI刷新的 key），死亡时统一分发奖励
  void applyDamage({
    required double amount,                          // 入射伤害 = ATK * (1 + atkBoost)
    required FloatingIslandPlayerComponent killer,   // 谁打的
    required Vector2 logicalOffset,                  // 飘字用
    required GlobalKey<ResourceBarState> resourceBarKey,
    double defPenetration = 0.0,                     // 可选：破甲 0~1（默认无）
  }) {
    if (isDead) return;

    // ===== 1) 结算防御 =====
    final double hpMax = (hp ?? 0).toDouble();
    if (hpMax <= 0) return;

    final double defVal   = (def ?? 0).toDouble();
    final double effDef   = (defVal * (1.0 - defPenetration)).clamp(0.0, 1e9);
    final double rawIn    = (amount.isNaN ? 0.0 : amount);
    final double realDmg  = max(1.0, rawIn - effDef);   // 至少 1 点伤害

    final double prevHp   = currentHp;
    currentHp             = max(0.0, min(hpMax, currentHp - realDmg));

    // ===== 2) 刷血条 =====
    if (hpBar != null && hp != null) {
      hpBar!.setStats(
        currentHp: currentHp.toInt(),
        maxHp: hp!.toInt(),
        atk: (atk ?? 0).toInt(),
        def: (def ?? 0).toInt(),
      );
    }

    // ===== 3) 飘伤害数字 =====
    try {
      final hitPos = logicalPosition - Vector2(0, size.y / 2 + 8);
      // 飘伤害数字（把 priority 提到 10010，压过血条/名字）
      final ft = FloatingTextComponent(
        text: '-${realDmg.toInt()}',
        logicalPosition: hitPos,
        color: Colors.redAccent,
        fontSize: 18,
      )..priority = 10010;          // 👈 提高层级

      parent?.add(ft);

    } catch (_) {}

    // ===== 4) 判死 → mark → 奖励分发 =====
    if (prevHp > 0 && currentHp <= 0 && !isDead) {
      isDead = true;

      // 4.1 先做持久化标记（仅 boss_*，只做一次）
      if (_isBossType && !deathMarked) {
        try {
          DeadBossStorage.markDeadBoss(
            tileKey: spawnedTileKey,
            position: logicalPosition.clone(),
            bossType: type ?? 'boss',
            size: size.clone(),
          );
          deathMarked = true;
        } catch (e) {
          debugPrint('[Mover][$type] markDeadBoss failed: $e');
        }
      }

      // 4.2 清理可视
      try {
        removeFromParent();
        hpBar?..removeFromParent(); hpBar = null;
        label?..removeFromParent(); label = null;
      } catch (_) {}

      // 4.3 统一奖励路由（各 Boss 的奖励逻辑在注册表里）
      BossRewardRegistry.dispatch(
        bossType: type ?? '',
        ctx: BossKillContext(
          player: killer,
          logicalOffset: logicalOffset,
          resourceBarKey: resourceBarKey,
        ),
        boss: this,
      );
    }
  }

  /// ❗️兼容旧调用：没有上下文时只做“扣血+自移除”，不会发奖励（打印警告）
  void takeDamage(double amount) {
    if (isDead) return;
    final prev = currentHp;
    currentHp = (currentHp - amount).clamp(0, (hp ?? 0));

    if (hpBar != null && hp != null) {
      hpBar!.setStats(
        currentHp: currentHp.toInt(),
        maxHp: hp!.toInt(),
        atk: (atk ?? 0).toInt(),
        def: (def ?? 0).toInt(),
      );
    }

    if (prev > 0 && currentHp <= 0) {
      isDead = true;
      // 最小化清理，提示开发者改用 applyDamage
      debugPrint(
          '[Mover][$type] takeDamage() 没有上下文 → 已自移除但未触发奖励。请改用 applyDamage(...)');
      removeFromParent();
      hpBar?.removeFromParent(); hpBar = null;
      label?.removeFromParent(); label = null;
    }
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

  void _autoResumeIfLegal() {
    if (ignoreTerrainInMove) return;
    if (spawner is! FloatingIslandDynamicSpawnerComponent) return;
    if (!_stoppedByIllegal) return;
    if (!isMoveLocked) return;

    final currentTerrain = spawner.getTerrainType(logicalPosition);
    final isLegal = currentTerrain != 'unknown' &&
        spawner.allowedTerrains.contains(currentTerrain);

    if (isLegal) {
      _resumeFromIllegal();
    }
  }

  void _resumeFromIllegal() {
    _relocateFailCount = 0;
    _relocateGraceFrames = 0;
    _stoppedByIllegal = false;
    isMoveLocked = false;
    pickNewTarget();
    _startTargetTimer();
    print('▶️ [Mover] 地形已合法，自动恢复（tile=$spawnedTileKey）');
  }

  void resumeMovement() {
    if (isDead) return;
    if (!_stoppedByIllegal) return;
    if (_resumeCooldown > 0) return; // 防抖
    _resumeFromIllegal();
    _resumeCooldown = 0.25;
  }

  // ====== 辅助：敌人与玩家是否在同一种允许地形 ======
  bool _sameAllowedTerrainAsPlayer(
      FloatingIslandDynamicSpawnerComponent sp,
      Vector2 enemyPos,
      Vector2 playerPos,
      ) {
    final tEnemy  = sp.getTerrainType(enemyPos);
    final tPlayer = sp.getTerrainType(playerPos);
    if (tEnemy == 'unknown' || tPlayer == 'unknown') return false;
    return tEnemy == tPlayer && sp.allowedTerrains.contains(tEnemy);
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
        if (_autoResumeCooldown <= 0) {
          _autoResumeCooldown = _autoResumeCheckInterval;
          _autoResumeIfLegal();
        }
      }
    }

    if (isMoveLocked) return;

    // ====== 自动追击（👣 同地形才追） ======
    if (enableAutoChase && autoChaseRange != null) {
      final player = game.descendants().whereType<FloatingIslandPlayerComponent>().firstOrNull;
      if (player != null) {
        final delta = player.logicalPosition - logicalPosition;
        final distance = delta.length;

        if (distance <= autoChaseRange!) {
          // 只有“同一种允许地形”才追
          if (spawner is FloatingIslandDynamicSpawnerComponent) {
            final sameTerrain = _sameAllowedTerrainAsPlayer(
              spawner as FloatingIslandDynamicSpawnerComponent,
              logicalPosition,
              player.logicalPosition,
            );
            if (!sameTerrain) {
              // 玩家在别的地形：不追、不翻、不改目标；维持原地/游走
              return;
            }
          }

          // 地形一致，正常追击
          final moveStep = delta.normalized() * speed * dt;
          final nextPos = logicalPosition + moveStep;

          if (spawner is FloatingIslandDynamicSpawnerComponent) {
            final nextTerrain = spawner.getTerrainType(nextPos);
            if (!spawner.allowedTerrains.contains(nextTerrain)) {
              // 下一步会越界地形 → 直接换游走目标，避免边缘抖动
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
