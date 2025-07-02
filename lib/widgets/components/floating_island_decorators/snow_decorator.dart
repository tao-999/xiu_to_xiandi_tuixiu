// lib/widgets/components/snow_decorator.dart

import 'package:flame/components.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';

class SnowDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  SnowDecorator({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    required this.seed,
  });

  @override
  Future<void> onLoad() async {
    // 静态雪堆
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'snow'},
        staticSpritesMap: {
          'snow': [
            StaticSpriteEntry('floating_island/snow_1.png', 1),
            StaticSpriteEntry('floating_island/snow_2.png', 1),
            StaticSpriteEntry('floating_island/snow_3.png', 1),
            StaticSpriteEntry('floating_island/snow_4.png', 1),
            StaticSpriteEntry('floating_island/snow_5.png', 1),
          ],
        },
        staticTileSize: 48.0,
        seed: seed,
        minCount: 2,
        maxCount: 5,
        minSize: 8.0,
        maxSize: 32.0,
      ),
    );

    // 动态雪花
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'snow'},
        dynamicSpritesMap: {
          'snow': [
            DynamicSpriteEntry('floating_island/snow_d_1.png', 1),
            DynamicSpriteEntry(
                'floating_island/snow_d_2.png',
                1,
                minSize: 4,
                maxSize: 16
            ),
          ],
        },
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectsPerTile: 1,
        maxDynamicObjectsPerTile: 3,
        minDynamicObjectSize: 8.0,
        maxDynamicObjectSize: 48.0,
        minSpeed: 10.0,
        maxSpeed: 30.0,
      ),
    );
  }
}
