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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugPrint('[DiplomacyMap] onLoad started.');

    WidgetsBinding.instance.addObserver(this);

    // 初始化地图生成器
    _noiseMapGenerator = DiplomacyNoiseTileMapGenerator(
      tileSize: 64.0,
      smallTileSize: 4,
      chunkPixelSize: 512,
      seed: 2024,
      frequency: 0.001,
      octaves: 6,
      persistence: 0.6,
    );
    await _noiseMapGenerator.onLoad();

    logicalOffset = -size / 2;

    _noiseMapGenerator.position = Vector2.zero();
    add(_noiseMapGenerator);

    _noiseMapGenerator
      ..viewScale = 1.0
      ..viewSize = size
      ..logicalOffset = logicalOffset;

    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset + size / 2,
      extra: size,
      forceImmediate: true,
    );

    // 添加宗门管理组件
    final sectManager = SectManagerComponent(
      grid: _noiseMapGenerator,
      getLogicalOffset: () => logicalOffset,
      getViewSize: () => size,
      sectImageSize: 128.0,
      sectCircleRadius: 200.0,
    );
    _noiseMapGenerator.add(sectManager);

    // 初始化玩家
    _player = ZongmenDiplomacyPlayerComponent()
      ..logicalPosition = Vector2.zero();
    _noiseMapGenerator.add(_player);

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

    // FPS显示
    add(
      FpsTextComponent()
        ..anchor = Anchor.topLeft
        ..position = Vector2(10, 10),
    );

    // 🌟加载保存位置
    final data = await ZongmenDiplomacyService.load();

    final sectPositions = data['sects'] as List<MapEntry<int, Vector2>>;
    final playerPosition = data['player'] as Vector2;

    // 恢复宗门位置
    for (final s in _noiseMapGenerator.children.whereType<SectComponent>()) {
      final found = sectPositions.firstWhere(
            (e) => e.key == s.info.id,
        orElse: () => MapEntry(s.info.id, s.worldPosition),
      );
      s.worldPosition = found.value;
    }

    // 恢复玩家位置
    _player.logicalPosition = playerPosition;

    // 🌟把视角对准玩家
    logicalOffset = _player.logicalPosition - size / 2;

    // 🌟后续持续跟随
    isCameraFollowing = true;

    debugPrint('[DiplomacyMap] onLoad completed with restored positions.');
  }

  /// 自动保存位置
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

  @override
  void update(double dt) {
    super.update(dt);

    const maxSize = DiplomacyNoiseTileMapGenerator.maxMapSize;
    final viewWidth = size.x;
    final viewHeight = size.y;

    // 跟随逻辑
    if (isCameraFollowing) {
      logicalOffset = _player.logicalPosition - size / 2;
    }

    // 限制视野范围
    logicalOffset.x = logicalOffset.x.clamp(
      -maxSize,
      maxSize - viewWidth,
    );
    logicalOffset.y = logicalOffset.y.clamp(
      -maxSize,
      maxSize - viewHeight,
    );

    // 更新地图视图
    _noiseMapGenerator
      ..viewScale = 1.0
      ..viewSize = size
      ..logicalOffset = logicalOffset;

    // 更新角色位置
    _player.position = _player.logicalPosition - logicalOffset;

    // 确保地图块加载
    _noiseMapGenerator.ensureChunksForView(
      center: logicalOffset + size / 2,
      extra: size,
      forceImmediate: false,
    );
  }

  /// 🌟新增：对外暴露定位方法
  void centerViewOnPlayer() {
    logicalOffset = _player.logicalPosition - size / 2;
    isCameraFollowing = true;
    debugPrint('📍 视角已定位到玩家');
  }
}
