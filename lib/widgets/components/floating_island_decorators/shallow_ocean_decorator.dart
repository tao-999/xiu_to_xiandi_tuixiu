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
    // 🌊 静态浅海
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
          ],
        },
        staticTileSize: 256,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 64,
        maxSize: 64,
        onStaticComponentCreated: (deco, terrain) {
          deco.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('🌿 静态装饰被角色撞: ${deco.spritePath}');
            }
          };
        },
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
            DynamicSpriteEntry('floating_island/shallow_ocean_2.png', 10),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 64,
        minSpeed: 10,
        maxSpeed: 30,
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
