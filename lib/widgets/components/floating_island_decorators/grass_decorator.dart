import 'dart:ui';

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
            StaticSpriteEntry('floating_island/grass_3.png', 10),
            StaticSpriteEntry('floating_island/grass_4.png', 1),
            StaticSpriteEntry('floating_island/grass_5.png', 10),
            StaticSpriteEntry('floating_island/grass_6.png', 10),
            StaticSpriteEntry('floating_island/grass_7.png', 10),
            StaticSpriteEntry('floating_island/grass_8.png', 10),
            StaticSpriteEntry('floating_island/grass_9.png', 10),
            StaticSpriteEntry('floating_island/grass_10.png', 10),
          ],
        },
        staticTileSize: 128.0,
        seed: seed,
        minCount: 5,
        maxCount: 10,
        minSize: 20.0,
        maxSize: 40.0,
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
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectSize: 16.0,
        maxDynamicObjectSize: 32.0,
        minSpeed: 10.0,
        maxSpeed: 20.0,
      ),
    );

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
            DynamicSpriteEntry('floating_island/grass_d_3.png', 1,
              defaultFacingRight: false,
              ignoreTerrainInMove: true,
              priority: 99999,
            ),
          ],
        },
        dynamicTileSize: 1333.0,
        seed: seed,
        minDynamicObjectSize: 256.0,
        maxDynamicObjectSize: 356.0,
        minSpeed: 10.0,
        maxSpeed: 20.0,
      ),
    );

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
            DynamicSpriteEntry('floating_island/qinglong.png', 1,
              atk: 2000,
              def: 1000,
              hp: 10000,
              labelText: '上古青龙',
              labelColor: Color(0xFF00CED1),
              priority: 9999,
              type: 'boss_3'
            ),
          ],
        },
        dynamicTileSize: 1235.0,
        seed: seed,
        minDynamicObjectSize: 100.0,
        maxDynamicObjectSize: 150.0,
        minSpeed: 50.0,
        maxSpeed: 75.0,
      ),
    );

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
            DynamicSpriteEntry('fate_recruit_charm.png', 1,
                priority: 9999,
                type: 'charm_1'
            ),
          ],
        },
        dynamicTileSize: 175.0,
        seed: seed,
        minDynamicObjectSize: 20.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 20.0,
        maxSpeed: 35.0,
      ),
    );

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
            DynamicSpriteEntry('recruit_ticket.png', 1,
                priority: 9999,
                type: 'recruit_ticket'
            ),
          ],
        },
        dynamicTileSize: 655.0,
        seed: seed,
        minDynamicObjectSize: 20.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 20.0,
        maxSpeed: 35.0,
      ),
    );
  }
}
