import 'dart:ui';

import 'package:flame/components.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

class FlowerFieldDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  FlowerFieldDecorator({
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
        allowedTerrains: {'flower_field'},
        staticSpritesMap: {
          'flower_field': [
            StaticSpriteEntry('herbs/1.png', 1),
            StaticSpriteEntry('herbs/2.png', 1),
            StaticSpriteEntry('herbs/3.png', 1),
            StaticSpriteEntry('herbs/4.png', 1),
            StaticSpriteEntry('herbs/5.png', 1),
            StaticSpriteEntry('herbs/6.png', 1),
            StaticSpriteEntry('herbs/7.png', 1),
            StaticSpriteEntry('herbs/8.png', 1),
            StaticSpriteEntry('herbs/9.png', 1),
            StaticSpriteEntry('herbs/10.png', 1),
            StaticSpriteEntry('herbs/11.png', 1),
            StaticSpriteEntry('herbs/12.png', 1),
            StaticSpriteEntry('herbs/13.png', 1),
            StaticSpriteEntry('herbs/14.png', 1),
            StaticSpriteEntry('herbs/15.png', 1),
            StaticSpriteEntry('herbs/16.png', 1),
            StaticSpriteEntry('herbs/17.png', 1),
            StaticSpriteEntry('herbs/18.png', 1),
            StaticSpriteEntry('herbs/19.png', 1),
            StaticSpriteEntry('herbs/20.png', 1),
          ],
        },
        staticTileSize: 160.0,
        seed: seed,
        minCount: 0,
        maxCount: 2,
        minSize: 45.0,
        maxSize: 60.0,
      ),
    );

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'flower_field'},
        staticSpritesMap: {
          'flower_field': [
            StaticSpriteEntry('floating_island/flower_field_1.png', 1),
            StaticSpriteEntry('floating_island/flower_field_2.png', 1),
            StaticSpriteEntry('floating_island/flower_field_3.png', 1),
            StaticSpriteEntry('floating_island/flower_field_4.png', 1),
            StaticSpriteEntry('floating_island/flower_field_5.png', 1),
            StaticSpriteEntry('floating_island/flower_field_6.png', 1),
          ],
        },
        staticTileSize: 138.0,
        seed: seed,
        minCount: 2,
        maxCount: 7,
        minSize: 30.0,
        maxSize: 40.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('floating_island/flower_field_d_1.png', 1),
          ],
        },
        dynamicTileSize: 128.0,
        seed: seed,
        minDynamicObjectSize: 8.0,
        maxDynamicObjectSize: 16.0,
        minSpeed: 15.0,
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
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('floating_island/flower_field_d_2.png', 1, priority: 9999, defaultFacingRight: false ,ignoreTerrainInMove: true),
          ],
        },
        dynamicTileSize: 1232.0,
        seed: seed,
        minDynamicObjectSize: 256.0,
        maxDynamicObjectSize: 300.0,
        minSpeed: 10.0,
        maxSpeed: 15.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('floating_island/zhuque.png', 1, priority: 9999, type: 'boss_3', labelText: '上古朱雀', labelColor:  Color(0xFFFF3B00), hp: 100000, atk: 4000, def: 2000, autoChaseRange: 300, enableAutoChase: true),
          ],
        },
        dynamicTileSize: 734.0,
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
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('gongfa/gongfa.png', 1, type: 'gongfa_1', labelText: '神秘功法', labelColor:  Color(0xFF000000))
          ],
        },
        dynamicTileSize: 540.0,
        seed: seed,
        minDynamicObjectSize: 16.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 10.0,
        maxSpeed: 25.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'flower_field'},
        dynamicSpritesMap: {
          'flower_field': [
            DynamicSpriteEntry('favorability.png', 1, type: 'favorability'),
          ],
        },
        dynamicTileSize: 350.0,
        seed: seed,
        minDynamicObjectSize: 16.0,
        maxDynamicObjectSize: 25.0,
        minSpeed: 10.0,
        maxSpeed: 25.0,
      ),
    );
  }
}
