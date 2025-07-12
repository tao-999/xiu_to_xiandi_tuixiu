import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_player_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

class RockDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  RockDecorator({
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
        allowedTerrains: {'rock'},
        staticSpritesMap: {
          'rock': [
            StaticSpriteEntry('floating_island/rock_1.png', 1,),
            StaticSpriteEntry('floating_island/rock_2.png', 1),
            StaticSpriteEntry(
                'floating_island/rock_3.png',
                1,
              minCount: 0,
              maxCount: 1,
            ),
          ],
        },
        staticTileSize: 64.0,
        seed: seed,
        minCount: 2,
        maxCount: 7,
        minSize: 8.0,
        maxSize: 48.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'rock'},
        dynamicSpritesMap: {
          'rock': [
            DynamicSpriteEntry('floating_island/rock_d_1.png', 1),
            DynamicSpriteEntry('floating_island/rock_d_2.png', 1),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 8,
        maxDynamicObjectSize: 32,
        minSpeed: 15,
        maxSpeed: 35,
        onDynamicComponentCreated: (mover, terrain) {
          mover.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('✨ 动态漂浮物被角色撞: ${mover.spritePath}');
            }
          };
        },
      ),
    );
  }
}
