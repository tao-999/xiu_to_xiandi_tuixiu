// 📂 lib/widgets/effects/world_vfx_bundle.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/vfx_world_snow_layer.dart';

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

      // 必开：atlas + 丝状雾
      useAtlas: true, atlasSize: 64, atlasVariants: 4, atlasOrganic: true,
      wispyMode: true,

      // ✨ 抗“长方形”关键：适度拉伸 + 足够重叠 + 轻抖动
      wispyAnisoMin: 1.5, wispyAnisoMax: 2.2,
      strandLenMin: 3, strandLenMax: 6,
      strandStepMin: 16, strandStepMax: 64, // 实际会被直径×(0.45~0.65)夹住
      strandJitter: 10,

      // 生成/回收/更新（稳帧）
      tileSize: 480.0,
      tilesFps: 24.0,
      tilesSlices: 3,
      spawnRectScale: 1.35,
      cleanupRectScale: 1.18,
      updateRectScale: 1.10,
      updatePatchSlices: 4,
      updateSlices: 2,

      // 数量交给预算控制
      budgetEnabled: true,
      puffsPer100kpx: 18,
      hardPuffCap: 1400,

      // 每 tile 产量适中（避免爆量）
      spawnProbability: 0.48,
      minPuffsPerTile: 10,
      maxPuffsPerTile: 26,
      density: 0.58,

      // 动态感
      globalWind: Vector2(10, -3),
      gustStrength: 0.50,
      gustSpeed: 0.32,

      mixMode: MistMixMode.hsv,
      seed: seed,
    )..priority = 9300;

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

    final snow = WorldSnowLayer(
      intensity: 0.2,
      wind: Vector2(0, 0),
      keepFactor: 1.0,
    )..priority = 11500;
    grid.add(snow);
  }
}
