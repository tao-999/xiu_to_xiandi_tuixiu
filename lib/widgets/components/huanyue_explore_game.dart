import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_chest_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_enemy_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/map_tile_layer.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/huanyue_door_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

import '../../utils/floating_island_cleanup_manager.dart';

class HuanyueExploreGame extends FlameGame with HasCollisionDetection {
  late int mapRows;
  late int mapCols;
  late double tileSize;

  final VoidCallback? onReload;

  late int currentFloor;
  PositionComponent? mapLayer;
  late HuanyuePlayerComponent player;
  late MapTileLayer mapTileLayer;
  late HuanyueDoorComponent doorComponent;
  bool isDragging = false;

  final StreamController<int> _floorController = StreamController<int>.broadcast();
  Stream<int> get floorStream => _floorController.stream;

  // 🟢 支持自定义tileSize
  final double? customTileSize;

  HuanyueExploreGame({
    this.onReload,
    this.customTileSize,
  });

  @override
  Future<void> onLoad() async {
    add(FpsTextComponent());

    final double screenHeight = size.y;

    // tileSize优先用外部传入，没有则自动适配
    if (customTileSize != null && customTileSize! > 0) {
      tileSize = customTileSize!;
    } else {
      const int defaultRows = 72;
      tileSize = screenHeight / defaultRows;
    }

    // 🟢 保证 mapRows 最小为1且一定是整数
    mapRows = (screenHeight / tileSize).floor();
    if (mapRows < 1) mapRows = 1;
    mapCols = mapRows;

    // tileSize重新修正，确保格子正好铺满屏幕高（无缝）
    tileSize = screenHeight / mapRows;

    await _initMapForCurrentFloor();
  }

  Future<void> _initMapForCurrentFloor() async {
    currentFloor = await HuanyueStorage.getFloor();
    _floorController.add(currentFloor);

    // 🟢 独立维护逻辑格子障碍（防止List.generate报错，必须mapRows>0, mapCols>0）
    final logicGrid = List.generate(mapRows, (y) => List.generate(mapCols, (x) => 1));
    final tileManager = TileManager();

    mapLayer?.removeFromParent();

    mapLayer = PositionComponent()
      ..anchor = Anchor.topLeft
      ..size = Vector2(mapCols * tileSize, mapRows * tileSize)
      ..position = Vector2.zero();
    add(mapLayer!);

    // 渐变色底板
    mapTileLayer = MapTileLayer(
      rows: mapRows,
      cols: mapCols,
      tileSize: tileSize,
      currentFloor: currentFloor,
    );
    mapLayer!.add(mapTileLayer);

    // 四周墙壁不可走
    for (int y = 0; y < mapRows; y++) {
      for (int x = 0; x < mapCols; x++) {
        if (x == 0 || y == 0 || x == mapCols - 1 || y == mapRows - 1) {
          logicGrid[y][x] = 0;
        }
      }
    }

    // 门组件
    doorComponent = HuanyueDoorComponent(
      tileSize: tileSize,
      grid: logicGrid,
      onEnterDoor: _enterNextFloor,
      currentFloor: currentFloor,
      tileManager: tileManager,
    );
    await mapLayer!.add(doorComponent);

    // 玩家出生点
    final startPos = await _loadPlayerPosition();
    player = HuanyuePlayerComponent(
      tileSize: tileSize,
      position: startPos,
      onEnterDoor: _enterNextFloor,
      doorPosition: doorComponent.position,
      currentFloor: currentFloor,
      tileManager: tileManager,
    );
    mapLayer!.add(player);

    // 怪物生成器
    mapLayer!.add(HuanyueEnemySpawner(
      rows: mapRows,
      cols: mapCols,
      tileSize: tileSize,
      floor: currentFloor,
      enemyCount: 15,
      tileManager: tileManager,
    )..priority = 10);

    // 宝箱生成器
    mapLayer!.add(HuanyueChestSpawner(
      grid: logicGrid,
      tileSize: tileSize,
      currentFloor: currentFloor,
      tileManager: tileManager,
    ));

    // 拖拽地图
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

    add(
      FloatingIslandCleanupManager(
        grid: mapLayer!,
        getLogicalOffset: () => -mapLayer!.position, // 因为拖拽偏移
        getViewSize: () => size,
        bufferSize: 100,
      ),
    );

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

    // 🚀 地图尺寸
    final mapWidth = mapCols * tileSize;
    final mapHeight = mapRows * tileSize;

    final rand = Random();

    // 四周留margin
    const double margin = 50;

    final x = margin + rand.nextDouble() * (mapWidth - margin * 2);
    final y = margin + rand.nextDouble() * (mapHeight - margin * 2);

    return Vector2(x, y);
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
      ..add('FloorInfo');
  }

  void _centerMapOn(Vector2 worldPos) {
    final screenCenter = size / 2;
    mapLayer!.position = screenCenter - worldPos;
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
