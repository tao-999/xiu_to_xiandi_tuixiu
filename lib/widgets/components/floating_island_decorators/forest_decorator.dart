import 'package:flame/components.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';

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
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_1.png', 1),
            StaticSpriteEntry('floating_island/tree_2.png', 1),
            StaticSpriteEntry('floating_island/tree_3.png', 1),
            StaticSpriteEntry('floating_island/tree_4.png', 1),
            StaticSpriteEntry('floating_island/tree_5.png', 1),
            StaticSpriteEntry(
              'floating_island/tile_zongmen_1.png',
              1,
              minSize: 32.0,
              maxSize: 128.0,
              minCount: 0,
              maxCount: 1,
              tileSize: 256.0,
            ),
          ],
        },
        dynamicSpritesMap: {
          'forest': [
            DynamicSpriteEntry('floating_island/tree_d_1.png', 1),
            DynamicSpriteEntry('floating_island/tree_d_2.png', 1),
            DynamicSpriteEntry('floating_island/tree_d_3.png', 1),
          ],
        },
        staticTileSize: 84.0,
        dynamicTileSize: 128.0,
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 9,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 2,
        minStaticObjectSize: 16.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 8.0,
        maxDynamicObjectSize: 64.0,
        minSpeed: 10.0,
        maxSpeed: 30.0,
      ),
    );
  }
}
