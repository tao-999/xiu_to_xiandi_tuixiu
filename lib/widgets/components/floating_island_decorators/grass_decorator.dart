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
    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'grass'},
        staticSpritesMap: {
          'grass': [
            StaticSpriteEntry('herbs/21.png', 1),
            StaticSpriteEntry('herbs/22.png', 1),
            StaticSpriteEntry('herbs/23.png', 1),
            StaticSpriteEntry('herbs/24.png', 1),
            StaticSpriteEntry('herbs/25.png', 1),
            StaticSpriteEntry('herbs/26.png', 1),
            StaticSpriteEntry('herbs/27.png', 1),
            StaticSpriteEntry('herbs/28.png', 1),
            StaticSpriteEntry('herbs/29.png', 1),
            StaticSpriteEntry('herbs/30.png', 1),
            StaticSpriteEntry('herbs/31.png', 1),
            StaticSpriteEntry('herbs/32.png', 1),
            StaticSpriteEntry('herbs/33.png', 1),
            StaticSpriteEntry('herbs/34.png', 1),
            StaticSpriteEntry('herbs/35.png', 1),
            StaticSpriteEntry('herbs/36.png', 1),
            StaticSpriteEntry('herbs/37.png', 1),
            StaticSpriteEntry('herbs/38.png', 1),
            StaticSpriteEntry('herbs/39.png', 1),
            StaticSpriteEntry('herbs/40.png', 1),
            StaticSpriteEntry('herbs/81.png', 1),
            StaticSpriteEntry('herbs/82.png', 1),
            StaticSpriteEntry('herbs/83.png', 1),
            StaticSpriteEntry('herbs/84.png', 1),
            StaticSpriteEntry('herbs/85.png', 1),
            StaticSpriteEntry('herbs/86.png', 1),
            StaticSpriteEntry('herbs/87.png', 1),
            StaticSpriteEntry('herbs/88.png', 1),
            StaticSpriteEntry('herbs/89.png', 1),
            StaticSpriteEntry('herbs/90.png', 1),
            StaticSpriteEntry('herbs/91.png', 1),
            StaticSpriteEntry('herbs/92.png', 1),
            StaticSpriteEntry('herbs/93.png', 1),
            StaticSpriteEntry('herbs/94.png', 1),
            StaticSpriteEntry('herbs/95.png', 1),
            StaticSpriteEntry('herbs/96.png', 1),
            StaticSpriteEntry('herbs/97.png', 1),
            StaticSpriteEntry('herbs/98.png', 1),
            StaticSpriteEntry('herbs/99.png', 1),
            StaticSpriteEntry('herbs/100.png', 1),
            StaticSpriteEntry('herbs/101.png', 1),
            StaticSpriteEntry('herbs/102.png', 1),
            StaticSpriteEntry('herbs/103.png', 1),
            StaticSpriteEntry('herbs/104.png', 1),
            StaticSpriteEntry('herbs/105.png', 1),

          ],
        },
        staticTileSize: 160.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 45.0,
        maxSize: 60.0,
      ),
    );

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
        minCount: 2,
        maxCount: 8,
        minSize: 45.0,
        maxSize: 60.0,
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
              atk: 3300,
              def: 2200,
              hp: 110000,
              labelText: '上古青龙',
              labelColor: Color(0xFF00CED1),
              priority: 9999,
              type: 'boss_3',
              enableAutoChase: true,
              autoChaseRange: 300,
            ),
          ],
        },
        dynamicTileSize: 635.0,
        seed: seed,
        minDynamicObjectSize: 60.0,
        maxDynamicObjectSize: 100.0,
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
