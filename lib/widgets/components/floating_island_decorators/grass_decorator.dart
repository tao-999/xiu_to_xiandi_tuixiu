import 'package:flame/components.dart';
import '../floating_island_static_spawner_component.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../dynamic_sprite_entry.dart';
import '../static_sprite_entry.dart';

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
    // 🌿 静态草
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
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
        staticTileSize: 64.0,
        seed: seed,
        minCount: 0,
        maxCount: 7,
        minSize: 8.0,
        maxSize: 48.0,
      ),
    );

    // 🌱 动态草
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'grass'},
        dynamicSpritesMap: {
          'grass': [
            DynamicSpriteEntry('floating_island/grass_d_1.png', 1),
            DynamicSpriteEntry('floating_island/grass_d_2.png', 1,
              defaultFacingRight: false,
            ),
          ],
        },
        dynamicTileSize: 64.0,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 8.0,
        maxDynamicObjectSize: 32.0,
        minSpeed: 10.0,
        maxSpeed: 20.0,
      ),
    );
  }
}
