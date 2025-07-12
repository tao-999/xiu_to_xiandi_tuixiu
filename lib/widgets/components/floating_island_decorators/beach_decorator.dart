import 'package:flame/components.dart';

import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

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
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'beach'},
        staticSpritesMap: {
          'beach': [
            StaticSpriteEntry('floating_island/beach_1.png', 1),
          ],
        },
        staticTileSize: 80.0,
        seed: seed,
        minCount: 1,
        maxCount: 8,
        minSize: 16.0,
        maxSize: 48.0,
      ),
    );
  }
}
