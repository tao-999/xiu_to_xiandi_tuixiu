import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../dynamic_sprite_entry.dart';
import '../floating_island_dynamic_spawner_component.dart';
import '../floating_island_player_component.dart';
import '../floating_island_static_spawner_component.dart';
import '../noise_tile_map_generator.dart';
import '../static_sprite_entry.dart';

class RockDecorator extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  RockDecorator({
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
        allowedTerrains: {'rock'},
        staticSpritesMap: {
          'rock': [
            StaticSpriteEntry('herbs/41.png', 1),
            StaticSpriteEntry('herbs/42.png', 1),
            StaticSpriteEntry('herbs/43.png', 1),
            StaticSpriteEntry('herbs/44.png', 1),
            StaticSpriteEntry('herbs/45.png', 1),
            StaticSpriteEntry('herbs/46.png', 1),
            StaticSpriteEntry('herbs/47.png', 1),
            StaticSpriteEntry('herbs/48.png', 1),
            StaticSpriteEntry('herbs/49.png', 1),
            StaticSpriteEntry('herbs/50.png', 1),
            StaticSpriteEntry('herbs/51.png', 1),
            StaticSpriteEntry('herbs/52.png', 1),
            StaticSpriteEntry('herbs/53.png', 1),
            StaticSpriteEntry('herbs/54.png', 1),
            StaticSpriteEntry('herbs/55.png', 1),
            StaticSpriteEntry('herbs/56.png', 1),
            StaticSpriteEntry('herbs/57.png', 1),
            StaticSpriteEntry('herbs/58.png', 1),
            StaticSpriteEntry('herbs/59.png', 1),
            StaticSpriteEntry('herbs/60.png', 1),
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

    add(
      FloatingIslandStaticSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'rock'},
        staticSpritesMap: {
          'rock': [
            StaticSpriteEntry('floating_island/rock_1.png', 40),
            StaticSpriteEntry('floating_island/rock_2.png', 30),
            StaticSpriteEntry('floating_island/rock_3.png', 2),
            StaticSpriteEntry('floating_island/rock_4.png', 10),
            StaticSpriteEntry('floating_island/rock_5.png', 10),
            StaticSpriteEntry('floating_island/rock_6.png', 10, priority: 0),
            StaticSpriteEntry('floating_island/rock_7.png', 10),
            StaticSpriteEntry('floating_island/rock_8.png', 10),
            StaticSpriteEntry('floating_island/rock_9.png', 10),
            StaticSpriteEntry('floating_island/rock_10.png', 10),
          ],
        },
        staticTileSize: 130.0,
        seed: seed,
        minCount: 1,
        maxCount: 2,
        minSize: 45.0,
        maxSize: 60.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'rock'},
        dynamicSpritesMap: {
          'rock': [
            DynamicSpriteEntry('floating_island/rock_d_1.png', 1, defaultFacingRight: false, priority: 9909),
            DynamicSpriteEntry('floating_island/rock_d_2.png', 1, priority: 9999),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 32,
        minSpeed: 50,
        maxSpeed: 80,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'rock'},
        dynamicSpritesMap: {
          'rock': [
            DynamicSpriteEntry('hell/diyu_1.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_2.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_3.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_4.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_5.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_6.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_7.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_8.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_9.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_10.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_11.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_12.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_13.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_14.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
            DynamicSpriteEntry('hell/diyu_15.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_16.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_17.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_18.png', 1, hp: 5000, atk: 150, def: 220, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999, defaultFacingRight: false),
          ],
        },
        dynamicTileSize: 184,
        seed: seed,
        minDynamicObjectSize: 40,
        maxDynamicObjectSize: 60,
        minSpeed: 35,
        maxSpeed: 75,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        noiseMapGenerator: noiseMapGenerator,
        allowedTerrains: {'rock'},
        dynamicSpritesMap: {
          'rock': [
            DynamicSpriteEntry('lingshi.png', 1, type: 'lingshi'),
          ],
        },
        dynamicTileSize: 288,
        seed: seed,
        minDynamicObjectSize: 20,
        maxDynamicObjectSize: 25,
        minSpeed: 35,
        maxSpeed: 55,
      ),
    );
  }
}
