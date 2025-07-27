import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';

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
    // 🏝️ 普通装饰物（不变）
    add(FloatingIslandStaticSpawnerComponent(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
      allowedTerrains: {'beach'},
      staticSpritesMap: {
        'beach': [
          StaticSpriteEntry('floating_island/beach_1.png', 10),
          StaticSpriteEntry('floating_island/beach_8.png', 5),
          StaticSpriteEntry('floating_island/beach_9.png', 2),
        ],
      },
      staticTileSize: 150.0,
      seed: seed,
      minCount: 2,
      maxCount: 6,
      minSize: 48.0,
      maxSize: 128.0,
    ));

    // 🧊 宝箱（不变）
    add(FloatingIslandStaticSpawnerComponent(
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
    ));

    // 🗿 雕塑（不变）
    add(FloatingIslandStaticSpawnerComponent(
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
    ));

    // 🧍 普通NPC（不变）
    add(FloatingIslandDynamicSpawnerComponent(
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
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
          ),
          DynamicSpriteEntry(
            'floating_island/npc_2.png',
            1,
            type: 'npc_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
          ),
          DynamicSpriteEntry(
            'floating_island/npc_3.png',
            1,
            type: 'npc_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
            defaultFacingRight: false,
          ),
          DynamicSpriteEntry(
            'floating_island/npc_4.png',
            1,
            type: 'npc_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
          ),
          DynamicSpriteEntry(
            'floating_island/npc_5.png',
            1,
            type: 'npc_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
            defaultFacingRight: false,
          ),
          DynamicSpriteEntry(
            'floating_island/npc_6.png',
            1,
            type: 'npc_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 24,
            defaultFacingRight: false,
          ),
        ],
      },
      dynamicTileSize: 256.0,
      seed: seed,
      minDynamicObjectsPerTile: 0,
      maxDynamicObjectsPerTile: 3,
      minSpeed: 15.0,
      maxSpeed: 55.0,
    ));

    add(FloatingIslandDynamicSpawnerComponent(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
      noiseMapGenerator: noiseMapGenerator,
      allowedTerrains: {'beach'},
      dynamicSpritesMap: {
        'beach': [
          DynamicSpriteEntry(
            'floating_island/beach_boss_1.png',
            1,
            type: 'boss_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 42,
            defaultFacingRight: false,
            hp: 1000,
            atk: 100,
            def: 50,
            enableAutoChase: true,
            autoChaseRange: 200,
          ),
          DynamicSpriteEntry(
            'floating_island/beach_boss_2.png',
            1,
            type: 'boss_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 42,
            defaultFacingRight: false,
            hp: 1500,
            atk: 120,
            def: 60,
            enableAutoChase: true,
            autoChaseRange: 200,
          ),
          DynamicSpriteEntry(
            'floating_island/beach_boss_3.png',
            1,
            type: 'boss_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 42,
            defaultFacingRight: false,
            hp: 1900,
            atk: 130,
            def: 70,
            enableAutoChase: true,
            autoChaseRange: 200,
          ),
          DynamicSpriteEntry(
            'floating_island/beach_boss_4.png',
            1,
            type: 'boss_1',
            generateRandomLabel: true,
            labelFontSize: 10,
            labelColor: const Color(0xFF000000),
            minDistance: 500.0,
            maxDistance: 5000.0,
            desiredWidth: 42,
            defaultFacingRight: false,
            hp: 1900,
            atk: 130,
            def: 70,
            enableAutoChase: true,
            autoChaseRange: 200,
          ),
        ]
      },
      dynamicTileSize: 800.0,
      seed: seed,
      minDynamicObjectsPerTile: 0,
      maxDynamicObjectsPerTile: 1,
      minSpeed: 40.0,
      maxSpeed: 85.0,
    ));
  }
}
