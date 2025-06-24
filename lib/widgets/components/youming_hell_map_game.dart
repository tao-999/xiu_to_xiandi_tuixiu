import 'dart:math';
import 'package:flame/experimental.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';

import 'hell_monster_component.dart';
import 'hell_player_component.dart';
import 'safe_zone_circle.dart';

class YoumingHellMapGame extends FlameGame with HasCollisionDetection {
  final BuildContext context;
  final int level;

  static const int tileSize = 32;
  static const int mapSize = 64;

  late final World world;
  late final CameraComponent cameraComponent;
  late final PositionComponent mapRoot;
  late final HellPlayerComponent player;

  final Map<int, Sprite> tileSprites = {};
  late Vector2 safeZoneCenter;
  final double safeZoneRadius = 64;

  final int monstersPerWave = 100;
  final int totalWaves = 3;
  int currentWave = 0;
  final List<List<HellMonsterComponent>> waves = [];

  YoumingHellMapGame(this.context, {required this.level});

  @override
  Future<void> onLoad() async {
    await _initCameraAndWorld();
    await _loadTileSprites();
    _generateTileMap();
    _addInteractionLayer();
    await _spawnPlayer();
    await _generateAllWaves();
    _loadWave(0);
  }

  Future<void> _initCameraAndWorld() async {
    mapRoot = PositionComponent(
      size: Vector2(tileSize * mapSize.toDouble(), tileSize * mapSize.toDouble()),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );
    world = World()..add(mapRoot);

    cameraComponent = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );
    addAll([world, cameraComponent]);
  }

  Future<void> _loadTileSprites() async {
    for (int i = 1; i <= 9; i++) {
      tileSprites[i] = await loadSprite('hell/diyu_tile_$i.webp');
    }
  }

  void _generateTileMap() {
    final rng = Random(level);
    final weighted = [
      ...Iterable.generate(16, (_) => 1),
      ...Iterable.generate(10, (_) => 2),
      ...Iterable.generate(7, (_) => 3),
      4, 4, 5, 5, 6, 7, 8, 9
    ];

    for (int row = 0; row < mapSize; row++) {
      for (int col = 0; col < mapSize; col++) {
        final spr = tileSprites[weighted[rng.nextInt(weighted.length)]]!;
        mapRoot.add(SpriteComponent(
          sprite: spr,
          size: Vector2.all(tileSize.toDouble()),
          position: Vector2(col * tileSize.toDouble(), row * tileSize.toDouble()),
          anchor: Anchor.topLeft,
        ));
      }
    }
  }

  void _addInteractionLayer() {
    add(DragMap(
      onDragged: _handleDrag,
      onTap: _handleTap,
    ));
  }

  void _handleDrag(Vector2 delta) {
    cameraComponent.stop();
    cameraComponent.moveBy(-delta);
  }

  void _handleTap(Vector2 canvasPosition) {
    final worldPos = cameraComponent.globalToLocal(canvasPosition);
    player.moveTo(worldPos);
    cameraComponent.follow(player);
  }

  Future<void> _spawnPlayer() async {
    // ✅ 安全区中心点
    safeZoneCenter = Vector2(mapRoot.size.x / 2, mapRoot.size.y / 2);

    // ✅ 主角组件（传入安全区参数）
    player = HellPlayerComponent(
      safeZoneCenter: safeZoneCenter,
      safeZoneRadius: safeZoneRadius,
    )..position = safeZoneCenter;

    // ✅ 加入地图
    mapRoot.add(player);

    // ✅ 相机追踪 + 设定边界
    cameraComponent.follow(player);
    cameraComponent.setBounds(
      Rectangle.fromPoints(Vector2.zero(), mapRoot.size.clone()),
      considerViewport: true,
    );

    // ✅ 添加安全区圈圈显示
    mapRoot.add(SafeZoneCircle(
      center: safeZoneCenter,
      radius: safeZoneRadius,
    ));
  }

  Future<void> _generateAllWaves() async {
    final rng = Random(level);
    waves.clear();

    int monsterId = 0; // 用于为每个怪物分配唯一的编号

    for (int wave = 0; wave < totalWaves; wave++) {
      final List<HellMonsterComponent> waveMonsters = [];

      final monsterSpeed = (20 + wave * 10).toDouble();
      final bossSpeed = (40 + wave * 10).toDouble();

      // 生成普通怪物
      for (int i = 0; i < monstersPerWave; i++) {
        final pos = _getValidSpawnPosition(rng);

        // 给每个怪物分配唯一编号
        final monster = HellMonsterComponent(
          id: monsterId++, // 分配一个唯一的 id
          level: level + wave,
          isBoss: false,
          waveIndex: wave,
          position: pos,
        )..priority = 10;

        monster.trackTarget(
          player,
          speed: monsterSpeed,
          safeCenter: safeZoneCenter,
          safeRadius: safeZoneRadius,
        );

        waveMonsters.add(monster);
      }

      // 生成Boss怪物
      final bossPos = _getBossSpawnPosition(rng);
      final boss = HellMonsterComponent(
        id: monsterId++, // 给Boss分配一个唯一的 id
        level: level + wave,
        isBoss: true,
        waveIndex: wave,
        position: bossPos,
      )..priority = 10;

      boss.trackTarget(
        player,
        speed: bossSpeed,
        safeCenter: safeZoneCenter,
        safeRadius: safeZoneRadius,
      );

      waveMonsters.add(boss);
      waves.add(waveMonsters);
    }
  }

  void _loadWave(int waveIndex) {
    if (waveIndex >= waves.length) return;
    currentWave = waveIndex;

    for (final monster in waves[waveIndex]) {
      mapRoot.add(monster);
    }
  }

  void checkWaveProgress() {
    final currentMonsters = waves[currentWave];
    final alive = currentMonsters.where((m) => m.isMounted).toList();

    if (alive.isEmpty && currentWave + 1 < totalWaves) {
      _loadWave(currentWave + 1);
    }
  }

  Vector2 _getValidSpawnPosition(Random rng) {
    while (true) {
      final pos = Vector2(
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
      );
      if ((pos - safeZoneCenter).length > safeZoneRadius + tileSize * 3) {
        return pos;
      }
    }
  }

  Vector2 _getBossSpawnPosition(Random rng) {
    final edgeX = rng.nextBool()
        ? rng.nextInt(mapSize ~/ 4) * tileSize + tileSize / 2
        : (mapSize - rng.nextInt(mapSize ~/ 4)) * tileSize + tileSize / 2;
    final edgeY = rng.nextBool()
        ? rng.nextInt(mapSize ~/ 4) * tileSize + tileSize / 2
        : (mapSize - rng.nextInt(mapSize ~/ 4)) * tileSize + tileSize / 2;
    return Vector2(edgeX.toDouble(), edgeY.toDouble());
  }

  @override
  Color backgroundColor() => Colors.black;
}
