import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';
import 'package:flutter/widgets.dart';

import 'floating_island_monster_component.dart';
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

    WidgetsBinding.instance.addObserver(this);
    debugPrint('[FloatingIslandMap] onLoad started.');

    // 地形生成器
    _noiseMapGenerator = NoiseTileMapGenerator(
      tileSize: 10.0,
      smallTileSize: 3.5,
      seed: 1337,
      frequency: 0.0005,
      octaves: 4,
      persistence: 0.5,
    );
    await _noiseMapGenerator.onLoad();

    _grid = InfiniteGridPainterComponent(generator: _noiseMapGenerator);
    debugPrint('[FloatingIslandMap] Grid created.');

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
      childBuilder: () => _grid,
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

    add(
      InfiniteContentSpawnerComponent(
        grid: _grid,
        getLogicalOffset: () => logicalOffset,
        getViewSize: () => size,
        getTerrainType: (worldPos) => _noiseMapGenerator.getTerrainTypeAtPosition(worldPos),
        allowedTerrains: {'mud'}, // 换成你想刷怪的地形
        tileSize: 128.0,
      ),
    );
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
