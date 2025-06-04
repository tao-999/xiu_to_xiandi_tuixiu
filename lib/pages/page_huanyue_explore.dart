// 📂 lib/pages/page_huanyue_explore.dart

import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floor_info_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_chest_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_enemy_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_tile_layer.dart';

// 🚪 门组件骚气导入
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_door_component.dart';

import '../services/huanyue_storage.dart';
import '../utils/tile_manager.dart';

class HuanyueExplorePage extends StatefulWidget {
  const HuanyueExplorePage({super.key});

  @override
  State<HuanyueExplorePage> createState() => _HuanyueExplorePageState();
}

class _HuanyueExplorePageState extends State<HuanyueExplorePage> {
  late HuanyueExploreGame _game;

  @override
  void initState() {
    super.initState();
    _game = HuanyueExploreGame(onReload: _reloadGame);
  }

  void _reloadGame() {
    setState(() {
      _game = HuanyueExploreGame(onReload: _reloadGame);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'FloorInfo': (_, game) =>
                      FloorInfoOverlay(game: game as HuanyueExploreGame),
                  'Loading': (_, __) => const LoadingOverlay(),
                },
                initialActiveOverlays: const ['FloorInfo'],
              ),
            ),
            const BackButtonOverlay(),
          ],
        );
      },
    );
  }
}

class HuanyueExploreGame extends FlameGame with HasCollisionDetection {
  static const int mapRows = 96;
  static const int mapCols = 96;
  static const double tileSize = 16;

  final VoidCallback? onReload;

  late int currentFloor;
  PositionComponent? mapLayer; // 改为可空变量
  late HuanyuePlayerComponent player;
  late MapTileLayer mapTileLayer;
  late HuanyueDoorComponent doorComponent;
  bool isDragging = false;

  final StreamController<int> _floorController = StreamController<int>.broadcast();
  Stream<int> get floorStream => _floorController.stream;

  HuanyueExploreGame({this.onReload});

  @override
  Future<void> onLoad() async {
    await _initMapForCurrentFloor();
  }

  Future<void> _initMapForCurrentFloor() async {
    currentFloor = await HuanyueStorage.getFloor();
    _floorController.add(currentFloor);

    final tileManager = TileManager();

    // ✅ 若已有旧 mapLayer，先移除
    mapLayer?.removeFromParent();

    mapLayer = PositionComponent()
      ..anchor = Anchor.topLeft
      ..size = Vector2(mapCols * tileSize, mapRows * tileSize)
      ..position = Vector2.zero();
    add(mapLayer!);

    mapTileLayer = MapTileLayer(
      rows: mapRows,
      cols: mapCols,
      tileSize: tileSize,
      currentFloor: currentFloor,
      tileManager: tileManager,
    );
    mapLayer!.add(mapTileLayer);
    mapTileLayer.setSafeScreenSize(Size(size.x, size.y));

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 30));
      return mapTileLayer.children.isEmpty;
    });
    mapTileLayer.buildGrid();

    doorComponent = HuanyueDoorComponent(
      tileSize: tileSize,
      grid: mapTileLayer.grid,
      onEnterDoor: _enterNextFloor,
      currentFloor: currentFloor,
      tileManager: tileManager,
    );
    await mapLayer!.add(doorComponent);

    final startPos = await _loadPlayerPosition();

    player = HuanyuePlayerComponent(
      tileSize: tileSize,
      grid: mapTileLayer.grid,
      position: startPos,
      onEnterDoor: _enterNextFloor,
      doorPosition: doorComponent.position,
      currentFloor: currentFloor,
      tileManager: tileManager,
    );
    mapLayer!.add(player);

    mapLayer!.add(HuanyueEnemySpawner(
      rows: mapRows,
      cols: mapCols,
      tileSize: tileSize,
      floor: currentFloor,
      enemyCount: 15,
      tileManager: tileManager,
    )..priority = 10);

    mapLayer!.add(HuanyueChestSpawner(
      grid: mapTileLayer.grid,
      tileSize: tileSize,
      currentFloor: currentFloor,
      tileManager: tileManager,
    ));

    add(DragMap(
      onDragged: (delta) {
        isDragging = true;
        mapLayer!.position += delta;
        _clampMapLayer();
      },
      onTap: (tapPos) {
        isDragging = false;
        final local = tapPos - mapLayer!.position;
        player.moveTo(local);
      },
    ));

    _centerMapOn(startPos);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isDragging && player.isMoving) {
      _centerMapOn(player.position);
    }
  }

  Future<Vector2> _loadPlayerPosition() async {
    final saved = await HuanyueStorage.getPlayerPosition();
    if (saved != null && saved != Vector2.zero()) return saved;
    return Vector2(5, 5) * tileSize + Vector2.all(tileSize / 2);
  }

  Future<void> _enterNextFloor() async {
    await HuanyueStorage.clearDoorPosition(currentFloor);
    currentFloor++;
    await HuanyueStorage.setFloor(currentFloor);
    _floorController.add(currentFloor);

    overlays.add('Loading');
    mapLayer?.removeFromParent();

    await Future.delayed(const Duration(milliseconds: 300));
    await _initMapForCurrentFloor();

    overlays
      ..remove('Loading')
      ..add('FloorInfo'); // ✅ 保证重新显示
  }

  void _centerMapOn(Vector2 worldPos) {
    final screenCenter = size / 2;
    mapLayer!.position = screenCenter - worldPos; // ✅ 已加 ! 断言
    _clampMapLayer();
  }

  void _clampMapLayer() {
    final screen = size;
    final scaledSize = mapLayer!.size.clone()..multiply(mapLayer!.scale);
    final minX = screen.x - scaledSize.x;
    final minY = screen.y - scaledSize.y;
    mapLayer!.position.x = mapLayer!.position.x.clamp(minX, 0.0);
    mapLayer!.position.y = mapLayer!.position.y.clamp(minY, 0.0);
  }

  @override
  void onRemove() {
    _floorController.close();
    super.onRemove();
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
