import 'dart:ui';

import 'package:flame/components.dart';
import '../floating_island_static_spawner_component.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../dynamic_sprite_entry.dart';
import '../static_sprite_entry.dart';

class ForestDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  ForestDecorator({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    required this.seed,
  });

  @override
  Future<void> onLoad() async {
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('herbs/61.png', 1),
            StaticSpriteEntry('herbs/62.png', 1),
            StaticSpriteEntry('herbs/63.png', 1),
            StaticSpriteEntry('herbs/64.png', 1),
            StaticSpriteEntry('herbs/65.png', 1),
            StaticSpriteEntry('herbs/66.png', 1),
            StaticSpriteEntry('herbs/67.png', 1),
            StaticSpriteEntry('herbs/68.png', 1),
            StaticSpriteEntry('herbs/69.png', 1),
            StaticSpriteEntry('herbs/70.png', 1),
            StaticSpriteEntry('herbs/71.png', 1),
            StaticSpriteEntry('herbs/72.png', 1),
            StaticSpriteEntry('herbs/73.png', 1),
            StaticSpriteEntry('herbs/74.png', 1),
            StaticSpriteEntry('herbs/75.png', 1),
            StaticSpriteEntry('herbs/76.png', 1),
            StaticSpriteEntry('herbs/77.png', 1),
            StaticSpriteEntry('herbs/78.png', 1),
            StaticSpriteEntry('herbs/79.png', 1),
            StaticSpriteEntry('herbs/80.png', 1),

          ],
        },
        staticTileSize: 160.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 45.0,
        maxSize: 60.0,
      ),
    );

    // 🌿静态树
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_1.png', 1),
            StaticSpriteEntry('floating_island/tree_4.png', 1),
            StaticSpriteEntry('floating_island/tree_5.png', 1),
            StaticSpriteEntry('floating_island/tree_8.png', 1),
            StaticSpriteEntry('floating_island/tree_9.png', 1),
            StaticSpriteEntry('floating_island/tree_14.png', 1),
          ],
        },
        staticTileSize: 150.0,
        seed: seed,
        minCount: 0,
        maxCount: 5,
        minSize: 50.0,
        maxSize: 60.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_2.png', 1),
            StaticSpriteEntry('floating_island/tree_6.png', 10),
            StaticSpriteEntry('floating_island/tree_7.png', 10),
            StaticSpriteEntry('floating_island/tree_10.png', 1),
          ],
        },
        staticTileSize: 227.0,
        seed: seed,
        minCount: 0,
        maxCount: 4,
        minSize: 80.0,
        maxSize: 100.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_15.png', 1, priority: 0),
          ],
        },
        staticTileSize: 187.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 20.0,
        maxSize: 40.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_3.png', 1),
          ],
        },
        staticTileSize: 555.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 200.0,
        maxSize: 256.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_11.png', 1, priority: 0),
            StaticSpriteEntry('floating_island/tree_12.png', 1, priority: 0),
            StaticSpriteEntry('floating_island/tree_13.png', 1, priority: 0),
          ],
        },
        staticTileSize: 477.0,
        seed: seed,
        minCount: 0,
        maxCount: 5,
        minSize: 8.0,
        maxSize: 12.0,
      ),
    );

    // 🌲动态移动的树
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'forest'},
        dynamicSpritesMap: {
          'forest': [
            DynamicSpriteEntry('floating_island/tree_d_1.png', 1,
              defaultFacingRight: false,
              priority: 9,
            ),
            DynamicSpriteEntry(
              'floating_island/tree_d_2.png',
              1,
              priority: 999,
            ),
            DynamicSpriteEntry('floating_island/tree_d_3.png', 1, priority: 999),
          ],
        },
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectSize: 20.0,
        maxDynamicObjectSize: 32.0,
        minSpeed: 20.0,
        maxSpeed: 70.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'forest'},
        dynamicSpritesMap: {
          'forest': [
            DynamicSpriteEntry('danyao.png', 1, type: 'danyao', enableMirror: false),
          ],
        },
        dynamicTileSize: 333.0,
        seed: seed,
        minDynamicObjectSize: 20.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 30.0,
        maxSpeed: 40.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'forest'},
        dynamicSpritesMap: {
          'forest': [
            DynamicSpriteEntry('floating_island/baihu.png', 1, priority: 0, type: 'boss_3', labelText: '上古白虎', labelColor:  Color(0xFFFFFAFA), hp: 120000, atk: 5000, def: 1500, defaultFacingRight: false, enableAutoChase: true, autoChaseRange: 300),
          ],
        },
        dynamicTileSize: 836.0,
        seed: seed,
        minDynamicObjectSize: 60.0,
        maxDynamicObjectSize: 100.0,
        minSpeed: 50.0,
        maxSpeed: 75.0,
      ),
    );
  }
}
