// 📂 lib/widgets/effects/world_vfx_bundle.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/noise_tile_map_generator.dart';
import 'vfx_world_mist_layer.dart';
import 'vfx_world_lightning_layer.dart';
import 'vfx_world_snow_layer.dart';

/// 用法：
/// _worldLayer.add(
///   WorldVfxBundle(
///     host: _worldLayer,
///     getLogicalOffset: () => logicalOffset, // 世界相机中心
///     getViewSize: () => game.size,          // 视口像素尺寸
///     noiseMapGenerator: _noiseMapGenerator!,// 地形/噪声采样
///   ),
/// );
class WorldVfxBundle extends Component with HasGameReference<FlameGame> {
  final PositionComponent host;                 // ✅ 父层（不再要求是 InfiniteGrid）
  final Vector2 Function() getLogicalOffset;    // 世界相机中心
  final Vector2 Function() getViewSize;         // 视口像素尺寸
  final NoiseTileMapGenerator noiseMapGenerator;

  // 可选：你想限制雾出现的地形
  final Set<String> mistAllowedTerrains;

  WorldVfxBundle({
    required this.host,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    this.mistAllowedTerrains = const {
      'forest','grass','rock','shallow_ocean','snow'
    },
    int? priority,
  }) : super(priority: priority ?? 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final seed = noiseMapGenerator.seed;
    String getTerrain(Vector2 p) =>
        noiseMapGenerator.getTerrainTypeAtPosition(p);

    // ===== 雾层 =====
    final mist = WorldMistLayer(
      // ⚠️ 那些旧版 Layer 构造函数里如果参数名是 grid，但类型写死成 InfiniteGrid，
      // 我们强转为 dynamic 传入（如果它们只拿来当父层，不会出事）
      grid: host as dynamic,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: getTerrain,
      noiseMapGenerator: noiseMapGenerator,
      allowedTerrains: mistAllowedTerrains,

      // 保留你之前的配置
      useAtlas: true, atlasSize: 64, atlasVariants: 4, atlasOrganic: true,
      wispyMode: true,
      wispyAnisoMin: 1.5, wispyAnisoMax: 2.2,
      strandLenMin: 3, strandLenMax: 6,
      strandStepMin: 16, strandStepMax: 64,
      strandJitter: 10,
      tileSize: 480.0,
      tilesFps: 24.0,
      tilesSlices: 3,
      spawnRectScale: 1.35,
      cleanupRectScale: 1.18,
      updateRectScale: 1.10,
      updatePatchSlices: 4,
      updateSlices: 2,
      budgetEnabled: true,
      puffsPer100kpx: 18,
      hardPuffCap: 1400,
      spawnProbability: 0.48,
      minPuffsPerTile: 10,
      maxPuffsPerTile: 26,
      density: 0.58,
      globalWind: Vector2(10, -3),
      gustStrength: 0.50,
      gustSpeed: 0.32,
      mixMode: MistMixMode.hsv,
      seed: seed,
    )..priority = 9300;
    host.add(mist);

    // ===== 闪电 =====
    final lightning = WorldLightningLayer(
      grid: host as dynamic,
      getLogicalOffset: getLogicalOffset,
      getViewSize: getViewSize,
      getTerrainType: getTerrain,
      noiseMapGenerator: noiseMapGenerator,
      tileSize: 250.0,
      seed: seed ^ 0xD00D,
      volcanicTerrains: const {'volcanic','rock'},
      tilesFps: 20.0,
      maxConcurrentStrikes: 2,
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
    )..priority = 1200;
    host.add(lightning);

    // ===== 雪 =====
    final snow = WorldSnowLayer(
      getViewSize: getViewSize,
      getLogicalOffset: getLogicalOffset,
      intensity: 0.2,
      wind: Vector2(0, 0),
      keepFactor: 1.0,
    )..priority = 11500;
    host.add(snow);
  }
}
