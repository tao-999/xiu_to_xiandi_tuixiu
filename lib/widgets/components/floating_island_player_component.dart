// 📂 lib/widgets/components/floating_island_player_component.dart

import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

import '../../utils/collision_logic_handler.dart';
import '../../utils/terrain_event_util.dart';
import 'floating_island_static_decoration_component.dart';
import 'resource_bar.dart';

// ✅ 周身气流特效
import '../effects/vfx_airflow.dart';

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
  final double moveSpeed = 120;

  // —— 位移变化通知 —— //
  final StreamController<Vector2> _positionStreamController =
  StreamController.broadcast();
  Stream<Vector2> get onPositionChangedStream =>
      _positionStreamController.stream;

  // —— 速度计算辅助 —— //
  Vector2 _lastLogicalPos = Vector2.zero();

  // —— 气流特效 —— //
  AirFlowEffect? _airflow;

  // —— 贴图路径 & 朝向 & 缓存 —— //
  late String _baseSpritePath; // e.g. icon_youli_${gender}.png（默认朝右）
  bool _facingLeft = false;
  final Map<String, Sprite> _spriteCache = {};

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

    // ✅ 默认朝右：路径不变
    _baseSpritePath = 'icon_youli_${player.gender}.png';
    await _applySpriteForFacing(left: false, keepSize: false); // 首次加载并设置尺寸

    // 画面初始位置居中
    position = game.size / 2;

    // ✅ 碰撞：先 passive，100ms 后 active，避免初始化误碰
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

    // ✅ 气流特效（跟随玩家中心）
    _airflow = AirFlowEffect(
      getWorldCenter: () => absolutePosition, // ✅ 脚底（bottomCenter）
      getHostSize: () => size,

      palette: [Colors.white],
      mixMode: ColorMixMode.hsv,
      baseRate: 170,
      ringRadius: 12,

      centerYFactor: 0.50,  // ✅ 从脚底上移 50% → 圆心=玩家几何中心
      radiusFactor: 0.46,
      pad: 1.8,
      arcHalfAngle: pi / 12,
      biasLeftX: 0.0,
      biasRightX: 0.0,

      debugArcColor: const Color(0xFFFF00FF),
      debugArcWidth: 1.5,
      debugArcSamples: 48,
    );
    parent?.add(_airflow!);

    _lastLogicalPos = logicalPosition.clone();
  }

  // —— 生命周期：更新帧 —— //
  @override
  void update(double dt) {
    super.update(dt);

    // —— 移动与朝向 —— //
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

      // ✅ 根据水平分量判断朝向 → 切贴图（不使用 scale.x）
      final bool nowFacingLeft = delta.x < 0;
      if (nowFacingLeft != _facingLeft) {
        _facingLeft = nowFacingLeft;
        _applySpriteForFacing(left: _facingLeft, keepSize: true);
      }

      _positionStreamController.add(logicalPosition);
    }

    // —— 同步地图逻辑偏移（让玩家处于屏幕中心的那套做法） —— //
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

    // —— 气流特效：按速度向量驱动 —— //
    final vel = (logicalPosition - _lastLogicalPos) /
        (dt <= 1e-6 ? 1e-6 : dt);
    _lastLogicalPos.setFrom(logicalPosition);

    if (_airflow != null) {
      _airflow!.enabled = true;
      _airflow!.moveVector = vel;
    }
  }

  // —— 生命周期：移除 —— //
  @override
  void onRemove() {
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

  // =========================
  // 内部：贴图加载 & 缓存
  // =========================

  /// 按当前朝向应用贴图。
  /// left=false 使用 `_baseSpritePath`
  /// left=true  使用 `_baseSpritePath` + `_left` 后缀（.png 前插入）
  Future<void> _applySpriteForFacing({
    required bool left,
    required bool keepSize,
  }) async {
    final path = left ? _withLeftSuffix(_baseSpritePath) : _baseSpritePath;
    final loaded = await _loadSpriteCached(path);

    // 首次需要根据原图等比缩放到固定宽度 32
    if (!keepSize && loaded != null) {
      final originalSize = loaded.srcSize;
      const fixedWidth = 32.0;
      final scaledHeight = originalSize.y * (fixedWidth / originalSize.x);
      size = Vector2(fixedWidth, scaledHeight);
    }
  }

  /// 带缓存的 Sprite 加载；加载失败自动回退到 base 图
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
      // 左图可能不存在：回退到基础图
      if (path != _baseSpritePath) {
        debugPrint('⚠️ 加载 $path 失败，回退至基础贴图 $_baseSpritePath；err=$e');
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
    // 兜底：没按 png 后缀也处理一下
    return '${basePath}_left';
  }
}
