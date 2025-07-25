import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

import '../../../utils/name_generator.dart';
import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
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
            StaticSpriteEntry('floating_island/beach_1.png', 50),
          ],
        },
        staticTileSize: 128.0,
        seed: seed,
        minCount: 5,
        maxCount: 10,
        minSize: 32.0,
        maxSize: 64.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'beach'},
        staticSpritesMap: {
          'beach': [
            StaticSpriteEntry('floating_island/beach_2.png', 1, type: 'baoxiang_1'),
          ],
        },
        staticTileSize: 512.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 32.0,
        maxSize: 64.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'beach'},
        staticSpritesMap: {
          'beach': [
            StaticSpriteEntry('floating_island/beach_3.png', 1, type: 'beach_diaosu'),
            StaticSpriteEntry('floating_island/beach_4.png', 1, type: 'beach_diaosu'),
            StaticSpriteEntry('floating_island/beach_5.png', 1, type: 'beach_diaosu'),
            StaticSpriteEntry('floating_island/beach_6.png', 1, type: 'beach_diaosu'),
            StaticSpriteEntry('floating_island/beach_7.png', 1, type: 'beach_diaosu'),
          ],
        },
        staticTileSize: 600.0,
        seed: seed,
        minCount: 0,
        maxCount: 1,
        minSize: 64.0,
        maxSize: 128.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'beach'},
        dynamicSpritesMap: {
          'beach': [
            DynamicSpriteEntry(
              'floating_island/npc_1.png',
              1,
              type: 'npc_1',
              generateRandomLabel: true, // 🌟随机生成名字
              labelFontSize: 10,
              labelColor: const Color(0xFF000000),
              minDistance: 500.0,
              maxDistance: 5000.0,
              desiredWidth: 32,
            ),
          ],
        },
        dynamicTileSize: 256.0,
        seed: seed,
        minDynamicObjectsPerTile: 1,
        maxDynamicObjectsPerTile: 4,
        minSpeed: 15.0,
        maxSpeed: 55.0,
      ),
    );
  }
}
