// 📄 lib/widgets/components/floating_island_map_component.dart
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
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

// ✅ 补这行：重基时要平移静态装饰的 worldPosition
import 'floating_island_static_decoration_component.dart';

// Boss奖励路由注册
import 'package:xiu_to_xiandi_tuixiu/logic/combat/boss_reward_registry.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss1_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss2_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/boss3_collision_handler.dart';

// GPU 噪声地形（Fragment Shader）
import '../effects/fbm_terrain_layer.dart';

class FloatingIslandMapComponent extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;

  // 仅用于“地形采样/逻辑”，不再进行 CPU 贴图绘制/分块生成
  NoiseTileMapGenerator? _noiseMapGenerator;

  // 世界承载层（替代原 _grid，用于挂载玩家/装饰/NPC 等）
  final PositionComponent _worldLayer = PositionComponent()..priority = -9500;

  // GPU 地形背景
  FbmTerrainLayer? _fbmLayer;

  final int seed;
  final GlobalKey<ResourceBarState> resourceBarKey;

  late final FloatingIslandDynamicSpawnerComponent spawner;

  FloatingIslandPlayerComponent? player;

  // ===== 相机（局部坐标，语义不变）=====
  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  // ===== 浮动原点（内部透明，不改变对外语义）=====
  // 👉 动态：基础周期 = 256 / frequency
  double _rebaseUnit = 1048576.0;      // 初始给个安全值；onLoad 后用频率覆盖
  double _rebaseThreshold = 524288.0;
  Vector2 _worldBase = Vector2.zero();  // 仅用于存档/日志
  Vector2 get worldBase => _worldBase;

  double _saveTimer = 0.0;
  static const double _autoSaveInterval = 5.0;

  // 防止重复注册（热重载/多次进入页面）
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
    required this.resourceBarKey,
  });

  // ====== 工具：有限性守卫 & 夹值（防 NaN/Inf）======
  double _finiteOr(double v, double dflt) => v.isFinite ? v : dflt;
  static const double _BASE_CAP = 1e30; // very large; safe for storage/log only
  double _clampAbs(double v, double cap) {
    if (!v.isFinite) return 0.0;
    if (v >  cap) return  cap;
    if (v < -cap) return -cap;
    return v;
  }

  void _updateRebaseUnitByFrequency(double freq) {
    final f = (freq.abs() > 1e-12) ? freq.abs() : 1e-12;
    _rebaseUnit = 256.0 / f;           // 基础周期
    _rebaseThreshold = _rebaseUnit * 0.5;
    debugPrint('[FloatingOrigin] rebaseUnit=$_rebaseUnit threshold=$_rebaseThreshold (freq=$f)');
  }

  // —— 浮动原点：把局部世界整体拉回原点附近（不改变任何外部用法）
  void _maybeRebaseWorld() {
    // 非有限保护（外挂/测试把坐标弄崩的情况）
    if (!logicalOffset.x.isFinite || !logicalOffset.y.isFinite) {
      debugPrint('[FloatingOrigin] Non-finite local offset, reset -> zero.');
      logicalOffset = Vector2.zero();
      player?.logicalPosition = Vector2.zero();
      return;
    }

    double sx = 0.0, sy = 0.0;

    if (logicalOffset.x.abs() > _rebaseThreshold) {
      sx = (logicalOffset.x / _rebaseUnit).truncateToDouble() * _rebaseUnit;
    }
    if (logicalOffset.y.abs() > _rebaseThreshold) {
      sy = (logicalOffset.y / _rebaseUnit).truncateToDouble() * _rebaseUnit;
    }
    if (sx == 0.0 && sy == 0.0) return;

    final shift = Vector2(sx, sy);

    // 1) 仅用于存档/日志的累计值（渲染与采样不用它）
    _worldBase = Vector2(
      _clampAbs(_worldBase.x + sx, _BASE_CAP),
      _clampAbs(_worldBase.y + sy, _BASE_CAP),
    );

    // 2) 局部世界整体减同样的量：玩家/相机/所有 mover 的“局部坐标”一起回缩
    logicalOffset -= shift;                // 相机保持画面不跳
    player?.logicalPosition -= shift;

    // 2.1 动态体（怪/Boss）
    for (final mover in _worldLayer.children.whereType<FloatingIslandDynamicMoverComponent>()) {
      mover.logicalPosition -= shift;
      mover.updateVisualPosition(logicalOffset);
    }

    // 2.2 ✅ 静态装饰：worldPosition 也要一起回缩
    for (final deco in _worldLayer.children.whereType<FloatingIslandStaticDecorationComponent>()) {
      deco.worldPosition -= shift;
      deco.updateVisualPosition(logicalOffset);
    }

    // 2.3 ✅ 通知所有静态刷子按新的相机偏移重刷（避免 _lastLogicalOffset 早退）
    for (final sp in descendants().whereType<FloatingIslandStaticSpawnerComponent>()) {
      sp.syncLogicalOffset(logicalOffset);
      sp.forceRefresh();
    }

    debugPrint('[FloatingOrigin] Rebased by $shift; base now = $_worldBase');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1) 先注册 Boss 奖励
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

    // 4) 仅用于“采样/逻辑”的地形生成器
    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 8,
      chunkPixelSize: 512,
      seed: seed,
      frequency: 0.00005,
      octaves: 10,
      persistence: 0.7,
      getWorldBase: () => worldBase,
    );

    // 👉 用频率计算“基础周期”作为重基单位（CPU/GPU 完全对齐）
    _updateRebaseUnitByFrequency(_noiseMapGenerator!.frequency);

    // 5) 世界承载层
    add(_worldLayer);
    _worldLayer.position = size / 2;

    // 6) GPU 背景：与 CPU 参数一致（octaves 夹到 8）
    final ng = _noiseMapGenerator!;
    final clampedOct = ng.octaves < 1 ? 1 : (ng.octaves > 8 ? 8 : ng.octaves);
    _fbmLayer = FbmTerrainLayer(
      getViewSize: () => size,                 // 屏幕像素
      getViewScale: () => 1.0,                 // 如有缩放改这里
      getLogicalOffset: () => logicalOffset,   // 世界相机中心（局部）
      getWorldBase: () => worldBase,
      frequency: ng.frequency,
      octaves: clampedOct,
      persistence: ng.persistence,
      seed: ng.seed,
      animate: false,
      priority: -10000,
      useLodAdaptive: true,
      lodNyquist: 0.5,
    );
    add(_fbmLayer!);

    // 7) 拖拽/点击交互（逻辑不变）
    _dragMap = DragMap(
      onDragged: (delta) {
        logicalOffset -= delta;
        isCameraFollowing = false;
        _maybeRebaseWorld(); // 防止拖太远
        debugPrint('[Map] Dragged logicalOffset=$logicalOffset (base=$_worldBase)');
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

    // 8) 初始化世界
    await _initGameWorld();

    // 9) 世界特效
    _worldLayer.add(
      WorldVfxBundle(
        host: _worldLayer,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        noiseMapGenerator: _noiseMapGenerator!,
      ),
    );

    // 10) 季节滤镜
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
    // ✅ worldBase 只用于存档/日志（渲染与采样不用它）
    final base = await FloatingIslandStorage.getWorldBase();
    _worldBase = base != null
        ? Vector2(_finiteOr(base['x']!, 0.0), _finiteOr(base['y']!, 0.0))
        : Vector2.zero();
    debugPrint('[FloatingIslandMap] Loaded worldBase: $_worldBase');

    // 读回“局部坐标”存档（保持老逻辑）
    final pos = await FloatingIslandStorage.getPlayerPosition();
    final cam = await FloatingIslandStorage.getCameraOffset();

    logicalOffset = cam != null ? Vector2(cam['x']!, cam['y']!) : Vector2.zero();
    debugPrint('[FloatingIslandMap] Loaded logicalOffset(local): $logicalOffset');

    _worldLayer.position = size / 2;

    player = FloatingIslandPlayerComponent(
      resourceBarKey: resourceBarKey,
    )..anchor = Anchor.bottomCenter;

    _worldLayer.add(player!);
    debugPrint('[FloatingIslandMap] Player added.');

    if (pos != null) {
      player!.logicalPosition = Vector2(pos['x']!, pos['y']!);
      debugPrint('[FloatingIslandMap] Loaded player logicalPosition(local): ${player!.logicalPosition}');
      player!.notifyPositionChanged();
      logicalOffset = player!.logicalPosition.clone();
      isCameraFollowing = true;
      player!.syncVisualPosition(logicalOffset);
    } else {
      player!.logicalPosition = Vector2.zero();
      logicalOffset = Vector2.zero();
      isCameraFollowing = true;
    }

    // 装饰/资源/NPC 等照旧，只是父层是 _worldLayer
    add(
      FloatingIslandDecorators(
        grid: _worldLayer,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        noiseMapGenerator: _noiseMapGenerator!,
        seed: seed,
      ),
    );

    add(
      DeadBossDecorationComponent(
        parentLayer: _worldLayer,
        getViewCenter: () => logicalOffset + size / 2,
        getViewSize: () => size,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (player != null) {
      if (isCameraFollowing) {
        logicalOffset = player!.logicalPosition.clone();
      }
      // 视觉位置 = 世界坐标 - 相机中心
      player!.position = player!.logicalPosition - logicalOffset;

      final movers = _worldLayer.children.whereType<FloatingIslandDynamicMoverComponent>();
      for (final mover in movers) {
        mover.updateVisualPosition(logicalOffset);
      }
    }

    // 超范围自动重基（透明，不改变对外语义）
    _maybeRebaseWorld();

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

    _worldLayer.position = newSize / 2;

    final movers = _worldLayer.children.whereType<FloatingIslandDynamicMoverComponent>();
    for (final mover in movers) {
      mover.updateVisualPosition(logicalOffset);
    }
    // 静态装饰也同步一下视觉位
    for (final deco in _worldLayer.children.whereType<FloatingIslandStaticDecorationComponent>()) {
      deco.updateVisualPosition(logicalOffset);
    }
  }

  Future<void> saveState() async {
    if (player != null) {
      // ✅ 存“局部”坐标（保持原逻辑）
      final pos = player!.logicalPosition;
      await FloatingIslandStorage.savePlayerPosition(pos.x, pos.y);
      debugPrint('[FloatingIslandMap] ✅ Saved playerPosition(local): x=${pos.x}, y=${pos.y}');
    } else {
      debugPrint('[FloatingIslandMap] ⚠️ Player is null, cannot save position');
    }

    final cam = logicalOffset; // ✅ 局部
    await FloatingIslandStorage.saveCameraOffset(cam.x, cam.y);

    // ✅ 另外存 worldBase（累计偏移），供日志/下次会话恢复（带保护）
    final bx = _clampAbs(_worldBase.x, _BASE_CAP);
    final by = _clampAbs(_worldBase.y, _BASE_CAP);
    await FloatingIslandStorage.saveWorldBase(bx, by);
    debugPrint('[FloatingIslandMap] ✅ Saved camera(local): x=${cam.x}, y=${cam.y}; base=[$bx,$by]');
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
    _worldLayer.position = size / 2;
    _maybeRebaseWorld(); // 保险
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
      _maybeRebaseWorld(); // 透明重基
    } else {
      debugPrint('[Map] No update needed, already centered.');
    }
  }

  NoiseTileMapGenerator? get noiseMapGenerator => _noiseMapGenerator;
}
