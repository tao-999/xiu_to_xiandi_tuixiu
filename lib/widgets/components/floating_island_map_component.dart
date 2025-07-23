import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';
import 'package:flutter/widgets.dart';

import '../../utils/floating_island_cleanup_manager.dart';
import 'floating_island_decorators.dart';
import 'floating_island_dynamic_mover_component.dart';
import 'floating_island_dynamic_spawner_component.dart';
import 'floating_island_static_spawner_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandMapComponent extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;
  late final InfiniteGridPainterComponent _grid;
  late final NoiseTileMapGenerator _noiseMapGenerator;

  final int seed;
  late final FloatingIslandDynamicSpawnerComponent spawner;

  FloatingIslandPlayerComponent? player;
  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  FloatingIslandMapComponent({
    this.seed = 8888,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      FpsTextComponent()
        ..anchor = Anchor.topLeft
        ..position = Vector2(10, 10),
    );

    WidgetsBinding.instance.addObserver(this);
    debugPrint('[FloatingIslandMap] onLoad started.');

    // 地形生成器
    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 4,
      chunkPixelSize: 512,
      seed: seed,
      frequency: 0.00005,
      octaves: 9,
      persistence: 0.6,
    );

    // ✅ 创建网格
    _grid = InfiniteGridPainterComponent(generator: _noiseMapGenerator);
    debugPrint('[FloatingIslandMap] Grid created.');
    add(_grid);

    // ✅ 创建 DragMap
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

    // 🌟 所有后续逻辑放到后台执行
    Future.microtask(() async {
      // 加载存档
      final pos = await FloatingIslandStorage.getPlayerPosition();
      final cam = await FloatingIslandStorage.getCameraOffset();

      if (cam != null) {
        logicalOffset = Vector2(cam['x']!, cam['y']!);
        debugPrint('[FloatingIslandMap] Loaded logicalOffset: $logicalOffset');
      } else {
        logicalOffset = Vector2.zero();
        debugPrint('[FloatingIslandMap] Default logicalOffset: $logicalOffset');
      }

      _grid.position = size / 2;

      // 玩家
      player = FloatingIslandPlayerComponent()..anchor = Anchor.bottomCenter;
      _grid.add(player!);
      debugPrint('[FloatingIslandMap] Player added.');

      if (pos != null) {
        player!.logicalPosition = Vector2(pos['x']!, pos['y']!);
        debugPrint('[FloatingIslandMap] Loaded player logicalPosition: ${player!.logicalPosition}');
        player!.notifyPositionChanged();
        logicalOffset = player!.logicalPosition.clone();
        isCameraFollowing = true;
      } else {
        player!.logicalPosition = Vector2.zero();
        debugPrint('[FloatingIslandMap] Default player logicalPosition: ${player!.logicalPosition}');
        logicalOffset = Vector2.zero();
        isCameraFollowing = true;
      }

      // 🌟 核心区域先分帧加载 (不阻塞)
      _noiseMapGenerator.ensureChunksForView(
        center: logicalOffset,
        extra: size * 1.2,
        forceImmediate: false,
      );

      // 🌟 周边区域分帧加载
      _noiseMapGenerator.ensureChunksForView(
        center: logicalOffset,
        extra: size * 2,
        forceImmediate: false,
      );

      // 🌟 装饰器
      add(
        FloatingIslandDecorators(
          grid: _grid,
          getLogicalOffset: () => logicalOffset,
          getViewSize: () => size,
          noiseMapGenerator: _noiseMapGenerator,
          seed: seed,
        ),
      );

      // 🌟 清理器
      add(
        FloatingIslandCleanupManager(
          grid: _grid,
          getLogicalOffset: () => logicalOffset,
          getViewSize: () => size,
          excludeComponents: {player!},
        ),
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    _grid
      ..viewScale = 1.0
      ..viewSize = size.clone();

    // 🌟先分帧加载（无论有没有player）
    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset,
      extra: size * 1.5,
      forceImmediate: false,
    );

    // 🌟如果有player，再更新逻辑
    if (player != null) {
      if (isCameraFollowing) {
        logicalOffset = player!.logicalPosition.clone();
      }

      _grid.generator.logicalOffset = logicalOffset;

      player!.position = player!.logicalPosition - logicalOffset;

      for (final mover in _grid.children.whereType<FloatingIslandDynamicMoverComponent>()) {
        mover.updateVisualPosition(logicalOffset);
      }
    }
  }

  Future<void> saveState() async {
    if (player != null) {
      await FloatingIslandStorage.savePlayerPosition(
        player!.logicalPosition.x,
        player!.logicalPosition.y,
      );
    }
    await FloatingIslandStorage.saveCameraOffset(
      logicalOffset.x,
      logicalOffset.y,
    );
  }

  @override
  void onRemove() {
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
    _grid.position = size / 2;
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

      _grid.generator.logicalOffset = logicalOffset;

      // 🌟 用 descendants()递归查找所有Spawner
      for (final c in descendants().whereType<FloatingIslandStaticSpawnerComponent>()) {
        debugPrint('[Map] Forcing tile rendering immediately for spawner=$c');
        c.forceRefresh();
      }
    } else {
      debugPrint('[Map] No update needed, already centered.');
    }
  }

  NoiseTileMapGenerator get noiseMapGenerator => _noiseMapGenerator;
}
