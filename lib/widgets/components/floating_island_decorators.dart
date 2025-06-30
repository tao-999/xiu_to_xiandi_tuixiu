import 'package:flame/components.dart';
import 'floating_island_decorators/beach_decorator.dart';
import 'floating_island_decorators/forest_decorator.dart';
import 'floating_island_decorators/grass_decorator.dart';
import 'floating_island_decorators/mud_decorator.dart';
import 'floating_island_decorators/shallow_ocean_decorator.dart';
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
    add(
      MudDecorator(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        noiseMapGenerator: noiseMapGenerator,
        seed: seed,
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
