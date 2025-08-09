// 📂 lib/widgets/effects/world_vfx_bundle.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/infinite_grid_painter_component.dart';
import '../components/noise_tile_map_generator.dart';
import 'vfx_world_mist_layer.dart';
import 'vfx_world_lightning_layer.dart';

/// 一句话用法：_grid!.add(WorldVfxBundle());
class WorldVfxBundle extends Component with HasGameReference<FlameGame> {
  @override
  void onMount() {
    super.onMount();

    // 父级必须是你的 _grid
    final grid = parent as InfiniteGridPainterComponent?;
    if (grid == null) return;

    final NoiseTileMapGenerator noise = grid.generator;
    final int seed = noise.seed;

    // 口径统一（世界相机中心 / 画布尺寸 / 地形函数）
    Vector2 getLogicalOffset() => noise.logicalOffset;
    Vector2 getViewSize()      => game.size; // ✅ HasGameReference 提供的是 game
    String  getTerrain(Vector2 p) => noise.getTerrainTypeAtPosition(p);

    // ===== 雾层 =====
    final mist = WorldMistLayer(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: getTerrain,
      noiseMapGenerator: noise,
      allowedTerrains: const {'forest','grass','rock','shallow_ocean','snow'},
      tileSize: 300.0,
      tilesFps: 10.0,
      seed: seed,
      spawnProbability: 0.858, // 128→300 面积补偿
      minPuffsPerTile: 15,
      maxPuffsPerTile: 30,
      density: 0.65,
      globalWind: Vector2(10, -3),
      gustStrength: 0.7,
      gustSpeed: 0.4,
      // 可选提速
      budgetEnabled: true,
      puffsPer100kpx: 35,
      hardPuffCap: 2000,
      updateSlices: 2,
      // useAtlas: true, atlasSize: 64,
    )..priority = 1100;
    grid.add(mist);

    // ===== 闪电（只在你给的地形）=====
    final lightning = WorldLightningLayer(
      grid: grid,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: getTerrain,
      noiseMapGenerator: noise,
      tileSize: 250.0,
      seed: seed ^ 0xD00D,
      volcanicTerrains: const {'volcanic','rock'},
      tilesFps: 20.0,
      maxConcurrentStrikes: 2,
      // 多色
      corePalette: const [
        Color(0xFFFFFFFF),
        Color(0xFFB3E5FF),
        Color(0xFFE2CCFF),
        Color(0xFFFFF1C1),
      ],
      glowPalette: const [
        Color(0xFF7FDBFF),
        Color(0xFFFFBB66),
        Color(0xFFB388FF),
        Color(0xFFB9F6CA),
      ],
      coreAlpha: 0.95,
      glowAlpha: 0.45,
    )..priority = 1200; // 闪电压雾层
    grid.add(lightning);
  }
}
