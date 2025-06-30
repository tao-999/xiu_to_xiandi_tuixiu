import 'package:flame/components.dart';

import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';

class BeachDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  BeachDecorator({
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
        allowedTerrains: {'beach'},
        staticSpritesMap: {
          'beach': [
            StaticSpriteEntry('floating_island/beach_1.png', 1),
          ],
        },
        dynamicSpritesMap: {},
        staticTileSize: 80.0,
        dynamicTileSize: 64.0,
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 8,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 0,
        minStaticObjectSize: 16.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 0.0,
        maxDynamicObjectSize: 0.0,
        minSpeed: 0.0,
        maxSpeed: 0.0,
      ),
    );
  }
}
