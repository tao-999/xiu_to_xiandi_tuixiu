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
        staticTileSize: 100.0,
        seed: seed,
        minCount: 1,
        maxCount: 2,
        minSize: 48.0,
        maxSize: 64.0,
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
            DynamicSpriteEntry('floating_island/rock_d_1.png', 1, defaultFacingRight: false),
            DynamicSpriteEntry('floating_island/rock_d_2.png', 1),
          ],
        },
        dynamicTileSize: 128,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 32,
        minSpeed: 50,
        maxSpeed: 120,
        onDynamicComponentCreated: (mover, terrain) {
          mover.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('✨ 动态漂浮物被角色撞: ${mover.spritePath}');
            }
          };
        },
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
            DynamicSpriteEntry('hell/diyu_1.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_2.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_3.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_4.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_5.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_6.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_7.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_8.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_9.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_10.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_11.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_12.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_13.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_14.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_15.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_16.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_17.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
            DynamicSpriteEntry('hell/diyu_18.png', 1, hp: 500, atk: 50, def: 20, type: 'boss_2', enableAutoChase: true, autoChaseRange: 200, priority: 999),
          ],
        },
        dynamicTileSize: 784,
        seed: seed,
        minDynamicObjectsPerTile: 0,
        maxDynamicObjectsPerTile: 1,
        minDynamicObjectSize: 48,
        maxDynamicObjectSize: 64,
        minSpeed: 35,
        maxSpeed: 75,
        onDynamicComponentCreated: (mover, terrain) {
          mover.onCustomCollision = (points, other) {
            if (other is FloatingIslandPlayerComponent) {
              debugPrint('✨ 动态漂浮物被角色撞: ${mover.spritePath}');
            }
          };
        },
      ),
    );
  }
}
