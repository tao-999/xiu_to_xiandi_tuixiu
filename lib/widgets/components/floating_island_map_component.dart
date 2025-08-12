// 📄 lib/widgets/components/floating_island_map_component.dart
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
// CPU 网格渲染已移除
// import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';

import '../effects/vfx_world_season_filter_layer.dart';
import '../effects/world_vfx_bundle.dart';
import 'dead_boss_decoration_component.dart';
import 'floating_island_decorators.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_static_spawner_component.dart';
import 'noise_tile_map_generator.dart';
import 'resource_bar.dart';

// 🆕 Boss奖励路由注册
import 'package:xiu_to_xiandi_tuixiu/logic/combat/boss_reward_registry.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss1_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss2_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss3_collision_handler.dart';

// 🆕 GPU 噪声地形（Fragment Shader）
import '../effects/fbm_terrain_layer.dart';

class FloatingIslandMapComponent extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;

  // ✅ 仅用于“地形采样/逻辑”，不再进行 CPU 贴图绘制/分块生成
  NoiseTileMapGenerator? _noiseMapGenerator;

  // ✅ 世界承载层（替代原 _grid，用于挂载玩家/装饰/NPC 等）
  // **修复点：** 不再 late，直接初始化，避免 onGameResize 早于 onLoad 触发的 LateInitializationError
  final PositionComponent _worldLayer = PositionComponent()..priority = -9500;

  // ✅ GPU 地形背景
  FbmTerrainLayer? _fbmLayer;

  final int seed;
  final GlobalKey<ResourceBarState> resourceBarKey; // ✅ 新增

  late final FloatingIslandDynamicSpawnerComponent spawner;

  FloatingIslandPlayerComponent? player;
  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  double _saveTimer = 0.0;
  static const double _autoSaveInterval = 5.0;
  double renderScale = 1.0;

  // 🆕 防止重复注册（热重载/多次进入页面）
  static bool _bossRewardsRegistered = false;
  void _registerBossRewardsOnce() {
    if (_bossRewardsRegistered) return;
    BossRewardRegistry.register('boss_1', Boss1CollisionHandler.onKilled);
    BossRewardRegistry.register('boss_2', Boss2CollisionHandler.onKilled);
    BossRewardRegistry.register('boss_3', Boss3CollisionHandler.onKilled);
    _bossRewardsRegistered = true;
  }

  FloatingIslandMapComponent({
    this.seed = 8888,
    required this.resourceBarKey, // ✅ 接收
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) 先注册 Boss 奖励（确保刷怪前就可用）
    _registerBossRewardsOnce();

    // 2) FPS HUD
    add(
      FpsTextComponent(
        textRenderer: TextPaint(style: const TextStyle(fontSize: 16)),
      )
        ..anchor = Anchor.topLeft
        ..position = Vector2(5, 5),
    );

    // 3) 生命周期监听
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[FloatingIslandMap] onLoad started.');

    // 4) 仅用于“采样/逻辑”的地形生成器（不再 CPU 画图）
    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 8,
      chunkPixelSize: 512,
      seed: seed,
      frequency: 0.00005,
      octaves: 10,
      persistence: 0.7,
    );

    // 5) 世界承载层（玩家/装饰/NPC 的父层）——先加进去防 Late
    add(_worldLayer);
    _worldLayer.position = size / 2;

    // 6) GPU 背景：fBm Shader（参数与 CPU 采样完全一致；octaves 夹到 8）
    final ng = _noiseMapGenerator!;
    final clampedOct = ng.octaves < 1 ? 1 : (ng.octaves > 8 ? 8 : ng.octaves);
    _fbmLayer = FbmTerrainLayer(
      getViewSize: () => size,               // 屏幕像素
      getViewScale: () => 1.0,               // 如有缩放改这里
      getLogicalOffset: () => logicalOffset, // 世界相机中心
      frequency: ng.frequency,
      octaves: clampedOct,                    // Shader 最多 8
      persistence: ng.persistence,
      seed: ng.seed,                          // ⚠️ 与 CPU seed 一致
      animate: false,
      priority: -10000,                       // 最底层
      useLodAdaptive: true,
      lodNyquist: 0.5,
    );
    add(_fbmLayer!);

    // 7) 拖拽/点击交互
    _dragMap = DragMap(
      onDragged: (delta) {
        logicalOffset -= delta;
        isCameraFollowing = false;
        debugPrint('[Map] Dragged logicalOffset=$logicalOffset');
      },
      onTap: (tapPos) {
        final worldPos = logicalOffset + (tapPos - size / 2);
        player?.moveTo(worldPos);
        isCameraFollowing = true;
        debugPrint('[Map] Tap to move and start following.');
      },
      showGrid: false,
    );
    add(_dragMap);
    debugPrint('[FloatingIslandMap] DragMap added.');

    // 8) 初始化世界（玩家位置/存档/装饰等）
    await _initGameWorld();

    // 9) 世界特效（雾/闪电/雪）挂在世界层
    _worldLayer.add(
      WorldVfxBundle(
        host: _worldLayer,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        noiseMapGenerator: _noiseMapGenerator!,
      ),
    );

    // 10) 季节滤镜（盖在大多数前景之上）
    add(
      WorldSeasonFilterLayer(
        getVisibleTopLeft: () => Vector2.zero(),
        getViewSize: () => size,
        fadeSmoothSec: 0.9,
        seasonPollIntervalSec: 4.0,
      )..priority = 9200,
    );
  }

  Future<void> _initGameWorld() async {
    final pos = await FloatingIslandStorage.getPlayerPosition();
    final cam = await FloatingIslandStorage.getCameraOffset();

    logicalOffset = cam != null
        ? Vector2(cam['x']!, cam['y']!)
        : Vector2.zero();

    debugPrint('[FloatingIslandMap] Loaded logicalOffset: $logicalOffset');

    // ✅ 世界层对齐屏幕中心（替代 _grid.position）
    _worldLayer.position = size / 2;

    player = FloatingIslandPlayerComponent(
      resourceBarKey: resourceBarKey,
    )..anchor = Anchor.bottomCenter;

    // ✅ 玩家挂到世界层
    _worldLayer.add(player!);
    debugPrint('[FloatingIslandMap] Player added.');

    if (pos != null) {
      player!.logicalPosition = Vector2(pos['x']!, pos['y']!);
      debugPrint('[FloatingIslandMap] Loaded player logicalPosition: ${player!.logicalPosition}');
      player!.notifyPositionChanged();
      logicalOffset = player!.logicalPosition.clone();
      isCameraFollowing = true;
      player!.syncVisualPosition(logicalOffset);
    } else {
      player!.logicalPosition = Vector2.zero();
      debugPrint('[FloatingIslandMap] Default player logicalPosition: ${player!.logicalPosition}');
      logicalOffset = Vector2.zero();
      isCameraFollowing = true;
    }

    // 🚫 不再生成 CPU chunk 图像，改为 GPU 着色器背景
    // _noiseMapGenerator?.ensureChunksForView(...)

    // ✅ 装饰/资源/NPC 等照旧，只是父层从 _grid 改为 _worldLayer
    add(
      FloatingIslandDecorators(
        grid: _worldLayer, // ✔ 作为承载父层
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        noiseMapGenerator: _noiseMapGenerator!, // ✔ 继续用于判地形
        seed: seed,
      ),
    );

    add(
      DeadBossDecorationComponent(
        parentLayer: _worldLayer, // ✔ 改成世界层
        getViewCenter: () => logicalOffset + size / 2,
        getViewSize: () => size,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 🚫 不再维护 _grid 的视图参数，也不再触发 CPU chunk
    // _noiseMapGenerator?.ensureChunksForView(...)

    if (player != null) {
      if (isCameraFollowing) {
        logicalOffset = player!.logicalPosition.clone();
      }

      // ✅ 视觉位置 = 世界坐标 - 相机中心
      player!.position = player!.logicalPosition - logicalOffset;

      // ✅ 同步所有 mover 的视觉位置
      final movers = _worldLayer.children.whereType<FloatingIslandDynamicMoverComponent>();
      for (final mover in movers) {
        mover.updateVisualPosition(logicalOffset);
      }
    }

    _saveTimer += dt;
    if (_saveTimer >= _autoSaveInterval) {
      _saveTimer = 0.0;
      saveState();
    }
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    debugPrint('[Map] 🖥️ onGameResize triggered: $newSize');

    // ✅ 世界层永远居中（onGameResize 可能早于 onLoad 调用，现在也安全了）
    _worldLayer.position = newSize / 2;

    // ✅ 让 mover 根据相机中心更新视觉位置
    final movers = _worldLayer.children.whereType<FloatingIslandDynamicMoverComponent>();
    for (final mover in movers) {
      mover.updateVisualPosition(logicalOffset);
    }
  }

  Future<void> saveState() async {
    if (player != null) {
      final pos = player!.logicalPosition;
      await FloatingIslandStorage.savePlayerPosition(pos.x, pos.y);
      debugPrint('[FloatingIslandMap] ✅ Saved playerPosition: x=${pos.x}, y=${pos.y}');
    } else {
      debugPrint('[FloatingIslandMap] ⚠️ Player is null, cannot save position');
    }

    final cam = logicalOffset;
    await FloatingIslandStorage.saveCameraOffset(cam.x, cam.y);
    debugPrint('[FloatingIslandMap] ✅ Saved cameraOffset: x=${cam.x}, y=${cam.y}');
  }

  @override
  void onRemove() {
    saveState();
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      saveState();
    }
  }

  void resetToCenter() {
    logicalOffset = Vector2.zero();
    isCameraFollowing = false;
    _worldLayer.position = size / 2; // ✅ 替代 _grid.position
  }

  void centerOnPlayer() {
    if (player == null) {
      debugPrint('[Map] centerOnPlayer: No player component.');
      return;
    }

    final targetOffset = player!.logicalPosition;
    final distance = (logicalOffset - targetOffset).length;
    debugPrint('[Map] centerOnPlayer called.\n  logicalOffset=$logicalOffset\n  playerPosition=$targetOffset\n  distance=$distance\n  size=$size');

    if (distance > 0.1) {
      logicalOffset = targetOffset.clone();
      isCameraFollowing = true;
      debugPrint('[Map] logicalOffset updated to $logicalOffset, isCameraFollowing=$isCameraFollowing');

      for (final c in descendants().whereType<FloatingIslandStaticSpawnerComponent>()) {
        debugPrint('[Map] Forcing tile rendering immediately for spawner=$c');
        c.forceRefresh();
      }
    } else {
      debugPrint('[Map] No update needed, already centered.');
    }
  }

  NoiseTileMapGenerator? get noiseMapGenerator => _noiseMapGenerator;
}
