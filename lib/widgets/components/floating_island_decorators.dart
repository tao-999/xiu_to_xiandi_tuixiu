import 'package:flame/components.dart';
import 'floating_island_decorators/beach_decorator.dart';
import 'floating_island_decorators/forest_decorator.dart';
import 'floating_island_decorators/grass_decorator.dart';
import 'floating_island_decorators/shallow_ocean_decorator.dart';
import 'infinite_content_spawner_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandDecorators extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  FloatingIslandDecorators({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    this.seed = 8888,
  });

  @override
  Future<void> onLoad() async {
    // 怪物生成
    add(
      InfiniteContentSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'mud'},
        tileSize: 64.0,
      ),
    );

    add(ForestDecorator(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      noiseMapGenerator: noiseMapGenerator,
      seed: seed,
    ));

    add(BeachDecorator(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      noiseMapGenerator: noiseMapGenerator,
      seed: seed,
    ));

    add(ShallowOceanDecorator(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      noiseMapGenerator: noiseMapGenerator,
      seed: seed,
    ));

    add(GrassDecorator(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      noiseMapGenerator: noiseMapGenerator,
      seed: seed,
    ));

  }
}
