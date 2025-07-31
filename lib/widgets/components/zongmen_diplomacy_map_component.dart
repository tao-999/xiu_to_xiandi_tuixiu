import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_info.dart';

import '../../services/zongmen_diplomacy_service.dart';
import 'drag_map.dart';
import 'diplomacy_noise_tile_map_generator.dart';
import 'sect_manager_component.dart';
import 'zongmen_diplomacy_player_component.dart';

class ZongmenDiplomacyMapComponent extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  late final DragMap _dragMap;
  late final DiplomacyNoiseTileMapGenerator _noiseMapGenerator;
  late final ZongmenDiplomacyPlayerComponent _player;

  Vector2 logicalOffset = Vector2.zero();
  bool isCameraFollowing = false;

  static const int chunkPixelSize = 512;
  static const int chunkCountX = 10;
  static const int chunkCountY = 10;

  double get mapWidth => chunkCountX * chunkPixelSize.toDouble();
  double get mapHeight => chunkCountY * chunkPixelSize.toDouble();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugPrint('[DiplomacyMap] onLoad started.');

    WidgetsBinding.instance.addObserver(this);

    final double mapWidth = this.mapWidth;
    final double mapHeight = this.mapHeight;

    debugPrint('[DiplomacyMap] 地图尺寸: $mapWidth x $mapHeight');

    _noiseMapGenerator = DiplomacyNoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 4,
      seed: 2024,
      frequency: 0.001,
      octaves: 6,
      persistence: 0.6,
    );
    await _noiseMapGenerator.onLoad();

    final Vector2 defaultPlayerPos = Vector2(mapWidth / 2, mapHeight / 2);
    debugPrint('[DiplomacyMap] 主角默认位置: $defaultPlayerPos');

    _player = ZongmenDiplomacyPlayerComponent()
      ..logicalPosition = defaultPlayerPos.clone();

    add(_noiseMapGenerator);
    await _noiseMapGenerator.add(_player);

    final sectManager = SectManagerComponent(
      grid: _noiseMapGenerator,
      getLogicalOffset: () => logicalOffset,
      getViewSize: () => size,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
      sectImageSize: 128.0,
      sectCircleRadius: 200.0,
    );
    await _noiseMapGenerator.add(sectManager);

    _dragMap = DragMap(
      onDragged: (delta) {
        if (_player.isMoving) return;
        logicalOffset -= delta;
        isCameraFollowing = false;
      },
      onTap: (canvasPos) {
        final target = logicalOffset + canvasPos;
        _player.moveTo(target);
        isCameraFollowing = true;
      },
      showGrid: false,
    );
    add(_dragMap);

    add(
      FpsTextComponent()
        ..anchor = Anchor.topLeft
        ..position = Vector2(10, 10),
    );

    final data = await ZongmenDiplomacyService.load();

    final savedSects = data['sects'] as List<Map<String, dynamic>>;
    final playerPosition = data['player'] as Vector2?;
    debugPrint('[DiplomacyMap] 存档玩家位置: $playerPosition');

    for (final s in _noiseMapGenerator.children.whereType<SectComponent>()) {
      final saved = savedSects.firstWhere(
            (e) => (e['info'] as SectInfo).id == s.info.id,
        orElse: () => {
          'info': s.info,
          'x': s.worldPosition.x,
          'y': s.worldPosition.y,
        },
      );

      s.worldPosition = Vector2(
        saved['x'] as double,
        saved['y'] as double,
      );
    }

    if (playerPosition != null &&
        playerPosition.x >= 0 && playerPosition.x < mapWidth &&
        playerPosition.y >= 0 && playerPosition.y < mapHeight) {
      _player.logicalPosition = playerPosition;
      debugPrint('[DiplomacyMap] 玩家位置已恢复: ${_player.logicalPosition}');
    } else {
      _player.logicalPosition = defaultPlayerPos.clone();
      debugPrint('[DiplomacyMap] 玩家位置使用默认: ${_player.logicalPosition}');
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

    debugPrint('[DiplomacyMap] onLoad completed. Player logical=${_player.logicalPosition}');
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

    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset + size / 2,
      extra: size,
      forceImmediate: false,
    );
  }

  @override
  Future<void> saveAllPositions() async {
    final sectData = _noiseMapGenerator.children
        .whereType<SectComponent>()
        .map((s) => {
      'id': s.info.id,
      'name': s.info.name,
      'level': s.info.level,
      'description': s.info.description,
      'masterName': s.info.masterName,
      'masterPower': s.info.masterPower,
      'discipleCount': s.info.discipleCount,
      'disciplePower': s.info.disciplePower,
      'spiritStoneLow': s.info.spiritStoneLow.toString(),
      'x': s.worldPosition.x,
      'y': s.worldPosition.y,
    })
        .toList();

    await ZongmenDiplomacyService.save(
      sectData: sectData,
      playerPosition: _player.logicalPosition,
    );

    debugPrint('[DiplomacyMap] ✅ 已保存全部宗门数据和坐标');
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
