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
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_1.png', 3),
            StaticSpriteEntry('floating_island/tree_2.png', 2),
            StaticSpriteEntry('floating_island/tree_3.png', 2),
            StaticSpriteEntry('floating_island/tree_4.png', 1),
            StaticSpriteEntry('floating_island/tree_5.png', 2),
          ],
        },
        dynamicSpritesMap: {}, // 禁用动态
        staticTileSize: 84.0,
        dynamicTileSize: 64.0,
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 9,
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
