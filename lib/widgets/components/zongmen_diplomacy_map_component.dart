import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_component.dart';

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

  /// 当前视角逻辑偏移
  Vector2 logicalOffset = Vector2.zero();

  /// 是否跟随角色
  bool isCameraFollowing = false;

  // ====== 这里与地图类参数保持一致 ======
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

    // 地图尺寸
    final double mapWidth = this.mapWidth;
    final double mapHeight = this.mapHeight;

    debugPrint('[DiplomacyMap] 地图尺寸: $mapWidth x $mapHeight');

    // 初始化地图生成器
    _noiseMapGenerator = DiplomacyNoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 4,
      seed: 2024,
      frequency: 0.001,
      octaves: 6,
      persistence: 0.6,
    );
    await _noiseMapGenerator.onLoad();

    // 主角初始化在地图中心
    final Vector2 defaultPlayerPos = Vector2(mapWidth / 2, mapHeight / 2);
    debugPrint('[DiplomacyMap] 主角默认位置: $defaultPlayerPos');

    _player = ZongmenDiplomacyPlayerComponent()
      ..logicalPosition = defaultPlayerPos.clone();

    // add地图
    add(_noiseMapGenerator);

    // add主角
    _noiseMapGenerator.add(_player);

    // 添加宗门管理
    final sectManager = SectManagerComponent(
      grid: _noiseMapGenerator,
      getLogicalOffset: () => logicalOffset,
      getViewSize: () => size,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
      sectImageSize: 128.0,
      sectCircleRadius: 200.0,
    );
    _noiseMapGenerator.add(sectManager);

    // 初始化拖拽
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

    // FPS
    add(
      FpsTextComponent()
        ..anchor = Anchor.topLeft
        ..position = Vector2(10, 10),
    );

    // 恢复存档
    final data = await ZongmenDiplomacyService.load();

    final sectPositions = data['sects'] as List<MapEntry<int, Vector2>>;
    final playerPosition = data['player'] as Vector2?;
    debugPrint('[DiplomacyMap] 存档玩家位置: $playerPosition');

    // 恢复宗门位置
    for (final s in _noiseMapGenerator.children.whereType<SectComponent>()) {
      final found = sectPositions.firstWhere(
            (e) => e.key == s.info.id,
        orElse: () => MapEntry(s.info.id, s.worldPosition),
      );
      s.worldPosition = found.value;
    }

    // 恢复玩家位置，越界兜底
    if (playerPosition != null &&
        playerPosition.x >= 0 && playerPosition.x < mapWidth &&
        playerPosition.y >= 0 && playerPosition.y < mapHeight) {
      _player.logicalPosition = playerPosition;
      debugPrint('[DiplomacyMap] 玩家位置已恢复: ${_player.logicalPosition}');
    } else {
      _player.logicalPosition = defaultPlayerPos.clone();
      debugPrint('[DiplomacyMap] 玩家位置使用默认: ${_player.logicalPosition}');
    }

    // 视角对准
    logicalOffset = _player.logicalPosition - size / 2;
    logicalOffset.x = logicalOffset.x.clamp(0.0, (mapWidth - size.x).clamp(0.0, double.infinity));
    logicalOffset.y = logicalOffset.y.clamp(0.0, (mapHeight - size.y).clamp(0.0, double.infinity));
    debugPrint('[DiplomacyMap] 初始逻辑偏移: $logicalOffset');

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
    final sectPositions = _noiseMapGenerator.children
        .whereType<SectComponent>()
        .map((s) => MapEntry(s.info.id, s.worldPosition))
        .toList();

    await ZongmenDiplomacyService.save(
      sectPositions: sectPositions,
      playerPosition: _player.logicalPosition,
    );

    debugPrint('[DiplomacyMap] 已保存位置');
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
