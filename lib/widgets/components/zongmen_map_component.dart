import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_disciples.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_building_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_building_manager_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/zongmen_diplomacy_disciple_component.dart';

import '../../pages/page_danfang.dart';
import '../../pages/page_lianqi.dart';
import '../../services/zongmen_diplomacy_service.dart';
import 'drag_map.dart';
import 'diplomacy_noise_tile_map_generator.dart';
import 'zongmen_diplomacy_player_component.dart';
import 'zongmen_disciple_spawner_component.dart';

class ZongmenMapComponent extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;
  late final DiplomacyNoiseTileMapGenerator _noiseMapGenerator;
  late final ZongmenDiplomacyPlayerComponent _player;

  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;
  bool isDragging = false;

  final int sectLevel;
  final BuildContext context; // ✅ 添加 context

  late final int chunkCountX;
  late final int chunkCountY;

  static const int chunkPixelSize = 256;

  double get mapWidth => chunkCountX * chunkPixelSize.toDouble();
  double get mapHeight => chunkCountY * chunkPixelSize.toDouble();

  ZongmenMapComponent({
    required this.sectLevel,
    required this.context, // ✅ 接收 context
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugPrint('[ZongmenMap] onLoad started.');
    WidgetsBinding.instance.addObserver(this);

    chunkCountX = 4 + (sectLevel - 1);
    chunkCountY = 4 + (sectLevel - 1);
    debugPrint('[ZongmenMap] chunkCountX=$chunkCountX, chunkCountY=$chunkCountY');

    final double mapWidth = this.mapWidth;
    final double mapHeight = this.mapHeight;
    debugPrint('[ZongmenMap] 地图尺寸: $mapWidth x $mapHeight');

    _noiseMapGenerator = DiplomacyNoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 2,
      seed: 2024,
      frequency: 0.001,
      octaves: 6,
      persistence: 0.5,
    );
    await _noiseMapGenerator.onLoad();

    final Vector2 defaultPlayerPos = Vector2(mapWidth / 2, mapHeight / 2);
    _player = ZongmenDiplomacyPlayerComponent()
      ..logicalPosition = defaultPlayerPos.clone();

    add(_noiseMapGenerator);
    await _noiseMapGenerator.add(_player);

    _dragMap = DragMap(
      onDragged: (delta) {
        if (_player.isMoving) return;
        logicalOffset -= delta;
        isCameraFollowing = false;
      },
      onDragStartCallback: () {
        isDragging = true;
      },
      onDragEndCallback: () {
        isDragging = false;
      },
      onTap: (canvasPos) {
        final target = logicalOffset + canvasPos;
        bool tappedBuilding = false;

        // ✅ 遍历所有建筑，判断是否点击命中
        final buildings = _noiseMapGenerator.children.whereType<SectBuildingComponent>();
        for (final building in buildings) {
          final center = building.worldPosition;
          final dist = center.distanceTo(target);
          if (dist <= building.circleRadius) {
            debugPrint('🏛 点击命中建筑：${building.buildingName} at $center');

            // ✅ 跳转对应页面
            switch (building.buildingName) {
              case '炼丹房':
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DanfangPage()));
                break;
              case '炼器房':
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LianqiPage()));
                break;
              case '弟子闺房':
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscipleListPage()));
                break;
              default:
                debugPrint('❓ 未知建筑：${building.buildingName}');
            }

            tappedBuilding = true;
            break;
          }
        }

        // ✅ 如果没点中建筑，再执行角色移动
        if (!tappedBuilding) {
          _player.moveTo(target);
          isCameraFollowing = true;
        }
      },
      showGrid: false,
    );
    add(_dragMap);

    add(FpsTextComponent()
      ..anchor = Anchor.topLeft
      ..position = Vector2(10, 10));

    final data = await ZongmenDiplomacyService.load();
    final playerPosition = data['player'] as Vector2?;
    debugPrint('[ZongmenMap] 存档玩家位置: $playerPosition');

    if (playerPosition != null &&
        playerPosition.x >= 0 && playerPosition.x < mapWidth &&
        playerPosition.y >= 0 && playerPosition.y < mapHeight) {
      _player.logicalPosition = playerPosition;
    } else {
      _player.logicalPosition = defaultPlayerPos.clone();
    }

    logicalOffset = _player.logicalPosition - size / 2;
    logicalOffset.x = logicalOffset.x.clamp(0.0, (mapWidth - size.x).clamp(0.0, double.infinity));
    logicalOffset.y = logicalOffset.y.clamp(0.0, (mapHeight - size.y).clamp(0.0, double.infinity));
    isCameraFollowing = true;

    _noiseMapGenerator
      ..viewScale = 1.0
      ..viewSize = size
      ..logicalOffset = logicalOffset;

    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset + size / 2,
      extra: size,
      forceImmediate: true,
    );

    // ✅ 添加弟子生成器
    Future.microtask(() {
      _noiseMapGenerator.add(
        ZongmenDiscipleSpawnerComponent(
          map: _noiseMapGenerator,
          getLogicalOffset: () => logicalOffset,
          getViewSize: () => size,
          getTerrainType: (pos) => _noiseMapGenerator.getTerrainTypeAtPosition(pos) ?? 'unknown',
          tileSize: _noiseMapGenerator.tileSize,
        ),
      );
    });

    // ✅ 添加建筑管理器（传入 context）
    Future.microtask(() {
      _noiseMapGenerator.add(
        SectBuildingManagerComponent(
          grid: _noiseMapGenerator,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          getLogicalOffset: () => logicalOffset,
        ),
      );
    });

    debugPrint('[ZongmenMap] onLoad completed. Player logical=${_player.logicalPosition}');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final viewWidth = size.x;
    final viewHeight = size.y;

    if (isCameraFollowing) {
      logicalOffset = _player.logicalPosition - size / 2;
    }

    logicalOffset.x = logicalOffset.x.clamp(0.0, (mapWidth - viewWidth).clamp(0.0, double.infinity));
    logicalOffset.y = logicalOffset.y.clamp(0.0, (mapHeight - viewHeight).clamp(0.0, double.infinity));

    _noiseMapGenerator
      ..viewScale = 1.0
      ..viewSize = size
      ..logicalOffset = logicalOffset;

    _player.position = _player.logicalPosition - logicalOffset;

    for (final d in _noiseMapGenerator.children.whereType<ZongmenDiplomacyDiscipleComponent>()) {
      d.updateVisualPosition(logicalOffset);
    }

    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset + size / 2,
      extra: size,
      forceImmediate: false,
    );
  }

  @override
  Future<void> saveAllPositions() async {
    await ZongmenDiplomacyService.save(
      sectData: const [],
      playerPosition: _player.logicalPosition,
    );
    debugPrint('[ZongmenMap] ✅ 已保存玩家坐标');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      saveAllPositions();
    }
  }

  @override
  void onRemove() {
    saveAllPositions();
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  void centerViewOnPlayer() {
    logicalOffset = _player.logicalPosition - size / 2;
    logicalOffset.x = logicalOffset.x.clamp(0.0, (mapWidth - size.x).clamp(0.0, double.infinity));
    logicalOffset.y = logicalOffset.y.clamp(0.0, (mapHeight - size.y).clamp(0.0, double.infinity));
    isCameraFollowing = true;
    debugPrint('📍 视角已定位到玩家');
  }
}
