import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';
import 'package:flutter/widgets.dart';

import 'floating_island_monster_component.dart';
import 'forest_tree_spawner_component.dart';
import 'infinite_content_spawner_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandMapComponent extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;
  late final InfiniteGridPainterComponent _grid;
  late final NoiseTileMapGenerator _noiseMapGenerator;

  FloatingIslandPlayerComponent? player;
  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(FpsTextComponent());

    WidgetsBinding.instance.addObserver(this);
    debugPrint('[FloatingIslandMap] onLoad started.');

    // 地形生成器
    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 16.0,
      smallTileSize: 3,
      seed: 1337,
      frequency: 0.0001,
      octaves: 5,
      persistence: 0.5,
    );
    await _noiseMapGenerator.onLoad();

    // ✅ 先创建网格
    _grid = InfiniteGridPainterComponent(generator: _noiseMapGenerator);
    debugPrint('[FloatingIslandMap] Grid created.');

    // ✅ 把_grid直接添加到地图
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

    await Future.delayed(Duration.zero);

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

    player = FloatingIslandPlayerComponent()..anchor = Anchor.center;
    _grid.add(player!);
    debugPrint('[FloatingIslandMap] Player added.');

    if (pos != null) {
      Future.microtask(() {
        player!.logicalPosition = Vector2(pos['x']!, pos['y']!);
        debugPrint('[FloatingIslandMap] Loaded player logicalPosition: ${player!.logicalPosition}');
        player!.notifyPositionChanged();

        logicalOffset = player!.logicalPosition.clone();
        isCameraFollowing = true;
        debugPrint('[FloatingIslandMap] Auto focus to player after load.');
      });
    } else {
      Future.microtask(() {
        player!.logicalPosition = Vector2.zero();
        debugPrint('[FloatingIslandMap] Default player logicalPosition: ${player!.logicalPosition}');
        logicalOffset = Vector2.zero();
        isCameraFollowing = true;
        debugPrint('[FloatingIslandMap] Auto focus to default position.');
      });
    }

    // 🌟 怪物生成器
    add(
      InfiniteContentSpawnerComponent(
        grid: _grid,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        getTerrainType: (worldPos) => _noiseMapGenerator.getTerrainTypeAtPosition(worldPos),
        allowedTerrains: {'mud'}, // 换成你想刷怪的地形
        tileSize: 64.0,
      ),
    );

    // 🌲 森林生成器（树木）
    add(
      ForestTreeSpawnerComponent(
        grid: _grid,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        getTerrainType: (pos) => _noiseMapGenerator.getTerrainTypeAtPosition(pos),
        terrainSpritesMap: {
          'forest': [
            'floating_island/tree_1.png',
            'floating_island/tree_2.png',
            'floating_island/tree_3.png',
            'floating_island/tree_4.png',
            'floating_island/tree_5.png',
          ],
        },
        tileSize: 64.0,
        seed: 8888,
        minTreesPerTile: 2,
        maxTreesPerTile: 5,
      ),
    );

    debugPrint('[FloatingIslandMap] ForestTreeSpawnerComponent added.');
  }

  @override
  void update(double dt) {
    super.update(dt);

    _grid
      ..viewScale = 1.0
      ..viewSize = size.clone();

    if (player != null) {
      if (isCameraFollowing) {
        logicalOffset = player!.logicalPosition.clone();
      }
      _grid.generator.logicalOffset = logicalOffset;

      player!.position = player!.logicalPosition - logicalOffset;
      for (final monster in _grid.children.whereType<FloatingIslandMonsterComponent>()) {
        monster.position = monster.logicalPosition - logicalOffset;
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
}
