import 'dart:math';
import 'package:flame/experimental.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';

import 'hell_monster_component.dart';
import 'hell_player_component.dart';

class YoumingHellMapGame extends FlameGame {
  final BuildContext context;
  final int level;

  static const int tileSize = 32;
  static const int mapSize = 64;

  late final World world;
  late final CameraComponent cameraComponent;
  late final PositionComponent mapRoot;
  late final HellPlayerComponent player;

  final Map<int, Sprite> tileSprites = {};

  YoumingHellMapGame(this.context, {required this.level});

  @override
  Future<void> onLoad() async {
    await _initCameraAndWorld();
    await _loadTileSprites();
    _generateTileMap();
    _addInteractionLayer();
    await _spawnMonsters();
    await _spawnPlayer();
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
    final weighted = [...Iterable.generate(16, (_) => 1),
      ...Iterable.generate(10, (_) => 2),
      ...Iterable.generate(7, (_) => 3),
      4,4,5,5,6,7,8,9];
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
    cameraComponent.viewfinder.position += delta;
  }

  void _handleTap(Vector2 canvasPosition) {
    final worldPos = cameraComponent.globalToLocal(canvasPosition);
    player.moveTo(worldPos); // ✅ 正确！方向+目标一起更新
  }

  Future<void> _spawnMonsters() async {
    final rng = Random(level);
    for (int i = 0; i < 10; i++) {
      final pos = Vector2(
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
      );
      mapRoot.add(HellMonsterComponent(level: level, isBoss: false, position: pos)..priority = 10);
    }
    mapRoot.add(HellMonsterComponent(
      level: level,
      isBoss: true,
      position: Vector2(mapRoot.size.x / 2, mapRoot.size.y / 2),
    )..priority = 10);
  }

  Future<void> _spawnPlayer() async {
    player = HellPlayerComponent()
      ..position = Vector2(mapRoot.size.x / 2, mapRoot.size.y / 2);
    mapRoot.add(player);

    // ✅ 跟踪玩家
    cameraComponent.follow(player);

    // ✅ 限制摄像机边界，防止黑屏
    cameraComponent.setBounds(
      Rectangle.fromPoints(
        Vector2.zero(),
        mapRoot.size.clone(),
      ),
      considerViewport: true,
    );
  }

  @override
  Color backgroundColor() => Colors.black;
}
