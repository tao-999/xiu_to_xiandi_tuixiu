import 'package:flame/components.dart';
import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../noise_tile_map_generator.dart';

class MudDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  MudDecorator({
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
        allowedTerrains: {'mud'},
        dynamicSpritesMap: {
          'mud': [
            DynamicSpriteEntry('floating_island/mud_d_1.png', 1),
            DynamicSpriteEntry('floating_island/mud_d_2.png', 1),
          ],
        },
        // 🌟全局动态配置
        dynamicTileSize: 64.0,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 3,
        minDynamicObjectSize: 4.0,
        maxDynamicObjectSize: 16.0,
        minSpeed: 5.0,
        maxSpeed: 10.0,
      ),
    );
  }
}
