import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';

import '../effects/vfx_world_mist_layer.dart';
import 'dead_boss_decoration_component.dart';
import 'floating_island_decorators.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_static_spawner_component.dart';
import 'noise_tile_map_generator.dart';
import 'resource_bar.dart';

class FloatingIslandMapComponent extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;
  InfiniteGridPainterComponent? _grid;
  NoiseTileMapGenerator? _noiseMapGenerator;

  final int seed;
  final GlobalKey<ResourceBarState> resourceBarKey; // ✅ 新增

  late final FloatingIslandDynamicSpawnerComponent spawner;

  FloatingIslandPlayerComponent? player;
  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  double _saveTimer = 0.0;
  static const double _autoSaveInterval = 5.0;
  double renderScale = 1.0;

  FloatingIslandMapComponent({
    this.seed = 8888,
    required this.resourceBarKey, // ✅ 接收
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      FpsTextComponent(
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 16),
        ),
      )
        ..anchor = Anchor.topLeft
        ..position = Vector2(5, 5),
    );

    WidgetsBinding.instance.addObserver(this);
    debugPrint('[FloatingIslandMap] onLoad started.');

    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 32.0,
      smallTileSize: 2,
      chunkPixelSize: 512,
      seed: seed,
      frequency: 0.00005,
      octaves: 10,
      persistence: 0.7,
    );

    _grid = InfiniteGridPainterComponent(generator: _noiseMapGenerator!);
    debugPrint('[FloatingIslandMap] Grid created.');
    add(_grid!);

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

    await _initGameWorld(); // ✅ 核心异步初始化

    if (_grid != null && _noiseMapGenerator != null) {
      final mist = WorldMistLayer(
        grid: _grid!,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        getTerrainType: (p) => _noiseMapGenerator!.getTerrainTypeAtPosition(p),
        noiseMapGenerator: _noiseMapGenerator!,
        allowedTerrains: {
          'forest','grass','rock','shallow_ocean','snow'
        },
        tileSize: 300.0,
        tilesFps: 10.0,        // ✅ 保留
        seed: seed,
        spawnProbability: 0.858,   // ✅ 面积补偿后的等效概率
        minPuffsPerTile: 15,       // ✅ 6×2.441 ≈ 14.6 → 15
        maxPuffsPerTile: 30,       // ✅ 12×2.441 ≈ 29.3 → 30
        density: 0.65,
        globalWind: Vector2(10, -3),
        gustStrength: 0.7,
        gustSpeed: 0.4,
        // （可选提速）
        budgetEnabled: true,
        puffsPer100kpx: 35,
        hardPuffCap: 2000,
        updateSlices: 2,
        // useAtlas: true, atlasSize: 64,
      );
      _grid!.add(mist);

    }
  }

  Future<void> _initGameWorld() async {
    final pos = await FloatingIslandStorage.getPlayerPosition();
    final cam = await FloatingIslandStorage.getCameraOffset();

    logicalOffset = cam != null
        ? Vector2(cam['x']!, cam['y']!)
        : Vector2.zero();

    debugPrint('[FloatingIslandMap] Loaded logicalOffset: $logicalOffset');

    _grid?.position = size / 2;

    player = FloatingIslandPlayerComponent(
      resourceBarKey: resourceBarKey,
    )..anchor = Anchor.bottomCenter;

    _grid?.add(player!);
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

    _noiseMapGenerator?.ensureChunksForView(
      center: logicalOffset,
      extra: size * 1.2,
      forceImmediate: true,
    );

    _noiseMapGenerator?.ensureChunksForView(
      center: logicalOffset,
      extra: size * 2,
      forceImmediate: true,
    );

    add(FloatingIslandDecorators(
      grid: _grid!,
      getLogicalOffset: () => logicalOffset,
      getViewSize: () => size,
      noiseMapGenerator: _noiseMapGenerator!,
      seed: seed,
    ));

    add(DeadBossDecorationComponent(
      parentLayer: _grid!,
      getViewCenter: () => logicalOffset + size / 2,
      getViewSize: () => size,
    ));

  }

  @override
  void update(double dt) {
    super.update(dt);

    _grid
      ?..viewScale = 1.0
      ..viewSize = size.clone();

    _noiseMapGenerator?.ensureChunksForView(
      center: logicalOffset,
      extra: size * 1.5,
      forceImmediate: false,
    );

    if (player != null) {
      if (isCameraFollowing) {
        logicalOffset = player!.logicalPosition.clone();
      }

      _grid?.generator.logicalOffset = logicalOffset;
      player!.position = player!.logicalPosition - logicalOffset;

      final movers = _grid?.children.whereType<FloatingIslandDynamicMoverComponent>();
      if (movers != null) {
        for (final mover in movers) {
          mover.updateVisualPosition(logicalOffset);
        }
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

    _grid
      ?..viewSize = newSize
      ..position = newSize / 2;

    _noiseMapGenerator?.ensureChunksForView(
      center: logicalOffset,
      extra: newSize * 1.5,
      forceImmediate: true,
    );

    final movers = _grid?.children.whereType<FloatingIslandDynamicMoverComponent>();
    if (movers != null) {
      for (final mover in movers) {
        mover.updateVisualPosition(logicalOffset);
      }
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
    _grid?.position = size / 2;
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

      _grid?.generator.logicalOffset = logicalOffset;

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
