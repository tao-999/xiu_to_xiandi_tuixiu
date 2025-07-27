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
          'shallow_ocean': [
            StaticSpriteEntry('floating_island/shallow_ocean_1.png', 1),
            StaticSpriteEntry('floating_island/shallow_ocean_2.png', 1),
          ],
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
            DynamicSpriteEntry('floating_island/shallow_ocean_d_4.png', 10, defaultFacingRight: false),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
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
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
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
            DynamicSpriteEntry('floating_island/shallow_ocean_d_1.png', 3),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_3.png', 5),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_5.png', 10, defaultFacingRight: false),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_6.png', 2, defaultFacingRight: false),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_7.png', 5),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_8.png', 5),
          ],
        },
        dynamicTileSize: 256,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 100,
        maxDynamicObjectSize: 128,
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
            DynamicSpriteEntry('floating_island/shallow_ocean_d_9.png', 1, enableMirror: false),
            DynamicSpriteEntry('floating_island/shallow_ocean_d_10.png', 1, enableMirror: false),
          ],
        },
        dynamicTileSize: 699,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 200,
        maxDynamicObjectSize: 256,
        minSpeed: 20,
        maxSpeed: 30,
      ),
    );
  }
}
