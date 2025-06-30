import 'package:flame/components.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';

class GrassDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  GrassDecorator({
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
        allowedTerrains: {'grass'},
        staticSpritesMap: {
          'grass': [
            StaticSpriteEntry('floating_island/grass_1.png', 4),
            StaticSpriteEntry('floating_island/grass_2.png', 2),
            StaticSpriteEntry('floating_island/grass_3.png', 1),
            StaticSpriteEntry('floating_island/grass_4.png', 1),
            StaticSpriteEntry('floating_island/grass_5.png', 1),
            StaticSpriteEntry('floating_island/grass_6.png', 1),
          ],
        },
        dynamicSpritesMap: {
          'grass': [
            DynamicSpriteEntry('floating_island/grass_d_1.png', 1),
            DynamicSpriteEntry('floating_island/grass_d_2.png', 1),
          ],
        },
        staticTileSize: 64.0,
        dynamicTileSize: 150.0,
        seed: seed,
        minStaticObjectsPerTile: 0,
        maxStaticObjectsPerTile: 7,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minStaticObjectSize: 8.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 8.0,
        maxDynamicObjectSize: 32.0,
        minSpeed: 10.0,
        maxSpeed: 20.0,
      ),
    );
  }
}
