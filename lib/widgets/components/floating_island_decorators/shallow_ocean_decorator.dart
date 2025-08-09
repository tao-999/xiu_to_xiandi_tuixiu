import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../floating_island_static_spawner_component.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_player_component.dart';
import '../noise_tile_map_generator.dart';
import '../dynamic_sprite_entry.dart';
import '../static_sprite_entry.dart';

class ShallowOceanDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  ShallowOceanDecorator({
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
        allowedTerrains: {'shallow_ocean'},
        staticSpritesMap: {
          'shallow_ocean': [],
        },
        staticTileSize: 512,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 128,
        maxSize: 128,
      ),
    );

    // 🌊 动态漂浮物
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'shallow_ocean'},
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_d_1.png', 3),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_4.png', 10, defaultFacingRight: false),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 32,
        minSpeed: 20,
        maxSpeed: 70,
      ),
    );
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'shallow_ocean'},
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_d_2.png', 5),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectSize: 48,
        maxDynamicObjectSize: 64,
        minSpeed: 20,
        maxSpeed: 70,
      ),
    );
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'shallow_ocean'},
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_d_3.png', 5, priority: 8888),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_5.png', 10, defaultFacingRight: false, priority: 8888),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_6.png', 2, defaultFacingRight: false, priority: 8888),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_7.png', 5, priority: 8888),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_8.png', 5, priority: 8888),
          ],
        },
        dynamicTileSize: 355,
        seed: seed,
        minDynamicObjectSize: 128,
        maxDynamicObjectSize: 168,
        minSpeed: 10,
        maxSpeed: 20,
      ),
    );
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'shallow_ocean'},
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_d_9.png', 1, enableMirror: false, priority: 9999),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_10.png', 1, enableMirror: false, priority: 9999),
          ],
        },
        dynamicTileSize: 799,
        seed: seed,
        minDynamicObjectSize: 200,
        maxDynamicObjectSize: 256,
        minSpeed: 20,
        maxSpeed: 30,
      ),
    );
  }
}
