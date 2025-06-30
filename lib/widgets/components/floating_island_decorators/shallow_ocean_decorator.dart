import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_player_component.dart';
import '../noise_tile_map_generator.dart';

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
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'shallow_ocean'},
        staticSpritesMap: {
          'shallow_ocean': [
            StaticSpriteEntry('floating_island/shallow_ocean_1.png', 1),
          ],
        },
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_2.png', 10),
          ],
        },
        staticTileSize: 256,
        dynamicTileSize: 128,
        minStaticObjectSize: 64,
        maxStaticObjectSize: 64,
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 48,
        minSpeed: 10,
        maxSpeed: 30,
        minStaticObjectsPerTile: 0,
        maxStaticObjectsPerTile: 1,
        minDynamicObjectsPerTile: 1,
        maxDynamicObjectsPerTile: 3,
        seed: seed,
        onDynamicComponentCreated: (mover, terrain) {
          mover.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('✨ 动态漂浮物被角色撞: ${mover.spritePath}');
            }
          };
        },
        onStaticComponentCreated: (deco, terrain) {
          deco.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('🌿 静态装饰被角色撞: ${deco.spritePath}');
            }
          };
        },
      ),
    );
  }
}
