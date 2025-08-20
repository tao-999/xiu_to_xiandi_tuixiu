// lib/widgets/components/volcanic_decorator.dart

import 'package:flame/components.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

class VolcanicDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  VolcanicDecorator({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    required this.seed,
  });

  @override
  Future<void> onLoad() async {
    // 静态火山装饰
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'volcanic'},
        staticSpritesMap: {
          'volcanic': [
            StaticSpriteEntry('floating_island/volcanic_1.png', 1),
            StaticSpriteEntry('floating_island/volcanic_3.png', 1, priority: 0),
            StaticSpriteEntry('floating_island/volcanic_4.png', 1, priority: 0),
          ],
        },
        staticTileSize: 166.0,
        seed: seed,
        minSize: 32.0,
        maxSize: 64.0,
        minCount: 1,
        maxCount: 2,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'volcanic'},
        staticSpritesMap: {
          'volcanic': [
            StaticSpriteEntry('floating_island/volcanic_2.png', 3),
          ],
        },
        staticTileSize: 126.0,
        seed: seed,
        minSize: 50.0,
        maxSize: 64.0,
        minCount: 2,
        maxCount: 6,
      ),
    );

    // 动态火山装饰
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'volcanic'},
        dynamicSpritesMap: {
          'volcanic': [
            DynamicSpriteEntry('floating_island/volcanic_d_1.png', 1, priority: 9999),
            DynamicSpriteEntry('floating_island/volcanic_d_2.png', 1, priority: 9999),
            DynamicSpriteEntry('floating_island/volcanic_d_3.png', 1, priority: 9999),
          ],
        },
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 12.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 10.0,
        maxSpeed: 30.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) =>
            noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'volcanic'},
        dynamicSpritesMap: {
          'volcanic': [
            DynamicSpriteEntry('jinkuang.png', 1, type: 'jinkuang', priority: 9999),
          ],
        },
        dynamicTileSize: 545.0,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 20.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 15.0,
        maxSpeed: 30.0,
      ),
    );
  }
}
