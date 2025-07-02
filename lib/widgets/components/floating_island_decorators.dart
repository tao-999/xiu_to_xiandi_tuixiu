import 'package:flame/components.dart';
import 'floating_island_decorators/beach_decorator.dart';
import 'floating_island_decorators/flower_field_decorator.dart';
import 'floating_island_decorators/forest_decorator.dart';
import 'floating_island_decorators/grass_decorator.dart';
import 'floating_island_decorators/mud_decorator.dart';
import 'floating_island_decorators/shallow_ocean_decorator.dart';
import 'floating_island_decorators/rock_decorator.dart';
import 'floating_island_decorators/snow_decorator.dart';
import 'floating_island_decorators/volcanic_decorator.dart';
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
    // 🟢 这里是装饰器构造器列表
    final builders = [
      MudDecorator.new,
      ForestDecorator.new,
      BeachDecorator.new,
      ShallowOceanDecorator.new,
      GrassDecorator.new,
      RockDecorator.new,
      FlowerFieldDecorator.new,
      SnowDecorator.new,
      VolcanicDecorator.new,
    ];

    // 🟢 批量add，每个自动注入所有公共参数
    for (final builder in builders) {
      add(builder(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        noiseMapGenerator: noiseMapGenerator,
        seed: seed,
      ));
    }
  }
}
