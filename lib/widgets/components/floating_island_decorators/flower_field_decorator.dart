import 'package:flame/components.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

class FlowerFieldDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  FlowerFieldDecorator({
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
        allowedTerrains: {'flower_field'},
        staticSpritesMap: {
          'flower_field': [
            StaticSpriteEntry('floating_island/flower_field_1.png', 1),
            StaticSpriteEntry('floating_island/flower_field_2.png', 1),
            StaticSpriteEntry('floating_island/flower_field_3.png', 1),
            StaticSpriteEntry('floating_island/flower_field_4.png', 1),
            StaticSpriteEntry('floating_island/flower_field_5.png', 1),
            StaticSpriteEntry('floating_island/flower_field_6.png', 1),
          ],
        },
        staticTileSize: 100.0,
        seed: seed,
        minCount: 10,
        maxCount: 25,
        minSize: 16.0,
        maxSize: 32.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('floating_island/flower_field_d_1.png', 1),
          ],
        },
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 16.0,
        maxDynamicObjectSize: 32.0,
        minSpeed: 15.0,
        maxSpeed: 55.0,
      ),
    );
  }
}
