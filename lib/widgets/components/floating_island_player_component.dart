// 📂 lib/widgets/components/floating_island_player_component.dart

import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/timer.dart' as f; // ✅ 用 Flame 的 Timer（update+onTick）
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../utils/collision_logic_handler.dart';
import '../../utils/terrain_event_util.dart';
import 'floating_island_static_decoration_component.dart';
import 'resource_bar.dart';

// ✅ 贴图控制器（朝向/缓存）
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_sprite_controller.dart';

// ✅ 气流特效适配器（一行装上，内部创建+更新；会按已装备“速度功法”自动取 palette）
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/airflow_player_adapter.dart';

class FloatingIslandPlayerComponent extends SpriteComponent
    with HasGameReference, CollisionCallbacks {
  FloatingIslandPlayerComponent({
    required this.resourceBarKey,
  }) : super(size: Vector2.all(32), anchor: Anchor.center, priority: 1000);

  // —— 外部依赖 —— //
  final GlobalKey<ResourceBarState> resourceBarKey;

  // —— 逻辑坐标 & 目标点 —— //
  Vector2 logicalPosition = Vector2.zero();
  Vector2? _targetPosition;

  // —— 实时移动速度（base*(1+boost)），由 PlayerStorage 计算 —— //
  double _curMoveSpeed = 100.0; // px/s
  late f.Timer _speedTimer;      // 轮询玩家最新速度

  // —— 位移变化通知 —— //
  final async.StreamController<Vector2> _positionStreamController =
  async.StreamController.broadcast();
  async.Stream<Vector2> get onPositionChangedStream =>
      _positionStreamController.stream;

  // —— 贴图控制器 —— //
  late PlayerSpriteController _spriteCtl;

  // —— 气流特效适配器 —— //
  late PlayerAirflowAdapter _airflowAdapter;

  // —— 对外方法 —— //
  void moveTo(Vector2 target) => _targetPosition = target;
  void stopMoving() => _targetPosition = null;
  bool get isMoving => _targetPosition != null;

  // 与 DragMap 同步：把逻辑坐标映射到画面位置
  void syncVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  void notifyPositionChanged() {
    _positionStreamController.add(logicalPosition);
  }

  // —— 生命周期：加载 —— //
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final player = await PlayerStorage.getPlayer();
    if (player == null) {
      debugPrint('[FloatingIslandPlayerComponent] ⚠️ Player未初始化');
      return;
    }

    // ✅ 初始化贴图（默认朝右），首帧把宽设置为 32，等比缩放高
    _spriteCtl = PlayerSpriteController(
      host: this,
      basePath: 'icon_youli_${player.gender}.png',
    );
    await _spriteCtl.init(keepSize: false, fixedWidth: 32);

    // ✅ 初始位置居中
    position = game.size / 2;

    // ✅ 初次读取 & 定期同步移动速度（每 0.25s）
    _curMoveSpeed = PlayerStorage.getMoveSpeed(player); // = base * (1 + boost)
    _speedTimer = f.Timer(
      0.25,
      repeat: true,
      onTick: () {
        // onTick 不能 async，这里包一层 IIFE
        () async {
          final p = await PlayerStorage.getPlayer();
          if (p != null) {
            _curMoveSpeed = PlayerStorage.getMoveSpeed(p);
          }
        }();
      },
    )..start();

    // ✅ 碰撞：先 passive，100ms 后 active（避免初始化误碰）
    final hitbox = RectangleHitbox()
      ..size = size
      ..collisionType = CollisionType.passive;
    add(hitbox);
    Future.delayed(const Duration(milliseconds: 100), () {
      hitbox.collisionType = CollisionType.active;
      debugPrint('✅ 玩家碰撞激活完毕');
    });

    // 首帧广播逻辑位置
    _positionStreamController.add(logicalPosition);

    // ✅ 一行装上气流特效（内部按已装备速度功法自动取颜色；没装备就不渲染）
    _airflowAdapter = PlayerAirflowAdapter.attach(
      host: this,
      logicalPosition: () => logicalPosition,
    );
  }

  // —— 生命周期：更新帧 —— //
  @override
  void update(double dt) {
    super.update(dt);

    // 驱动速度计时器
    _speedTimer.update(dt);

    // —— 移动与朝向 —— //
    if (_targetPosition != null) {
      final delta = _targetPosition! - logicalPosition;
      final distance = delta.length;
      final moveStep = _curMoveSpeed * dt; // ✅ 使用实时速度

      if (distance <= moveStep) {
        logicalPosition = _targetPosition!;
        _targetPosition = null;
      } else {
        logicalPosition += delta.normalized() * moveStep;
      }

      // ✅ 根据水平分量判断朝向 → 交给控制器换贴图
      final bool nowFacingLeft = delta.x < 0;
      if (nowFacingLeft != _spriteCtl.facingLeft) {
        _spriteCtl.faceLeft(nowFacingLeft, keepSize: true);
      }

      _positionStreamController.add(logicalPosition);
    }

    // —— 同步地图逻辑偏移（让玩家居中） —— //
    final mapGame = game as dynamic;
    if (_targetPosition != null) {
      mapGame.logicalOffset = logicalPosition.clone();
    }

    // —— 静态装饰锁定状态 —— //
    final staticList = parent?.children
        .whereType<FloatingIslandStaticDecorationComponent>()
        .toList();
    if (staticList != null) {
      CollisionLogicHandler.updateLockStatus(logicalPosition, staticList);
    }

    // —— 触发地形事件（异步微任务） —— //
    final noiseGenerator = mapGame.noiseMapGenerator;
    final currentTerrain =
    noiseGenerator.getTerrainTypeAtPosition(logicalPosition);
    Future.microtask(() async {
      final triggered = await TerrainEventUtil.checkAndTrigger(
        currentTerrain,
        logicalPosition,
        game,
      );
      if (triggered) {
        _targetPosition = null;
      }
    });
  }

  // —— 生命周期：移除 —— //
  @override
  void onRemove() {
    _speedTimer.stop();
    _positionStreamController.close();
    super.onRemove();
  }

  // —— 碰撞回调 —— //
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final mapGame = game as dynamic;

    CollisionLogicHandler.handleCollision(
      player: this,
      logicalOffset: mapGame.logicalOffset,
      other: other,
      resourceBarKey: resourceBarKey,
    );
  }
}
