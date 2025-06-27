import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';
import '../components/tile_overlay_renderer_manager.dart';

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize;
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();

  late final NoiseUtils _noise;
  late final TileOverlayRendererManager _overlayManager;

  bool _overlayLoaded = false;

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.seed = 1337,
    this.frequency = 0.005,
    this.octaves = 4,
    this.persistence = 0.5,
  }) {
    _noise = NoiseUtils(seed);
    _overlayManager = TileOverlayRendererManager(seed: seed);

    // 注册需要加载的贴图
    _overlayManager.register(terrainType: 'forest', tileType: 'tree');
  }

  @override
  Future<void> onLoad() async {
    // 异步加载贴图
    Future(() async {
      await _overlayManager.loadAllAssets();
      _overlayLoaded = true;
    });
  }

  /// 🌈 地形区间 + 渐变色配置
  final List<_TerrainRange> terrainRanges = [
    _TerrainRange('deep_ocean', 0.0, 0.18, Color(0xFF001F2D), Color(0xFF00334D)),
    _TerrainRange('shallow_ocean', 0.18, 0.32, Color(0xFF3E9DBF), Color(0xFF4DA6C3)),
    _TerrainRange('beach', 0.32, 0.42, Color(0xFFEED9A0), Color(0xFFF3E2B7)),
    _TerrainRange('grass', 0.42, 0.52, Color(0xFF6C9A5E), Color(0xFF77A865)),
    _TerrainRange('mud', 0.52, 0.61, Color(0xFF4A3628), Color(0xFF5C4431)),
    _TerrainRange('forest', 0.61, 0.70, Color(0xFF2E5530), Color(0xFF3A663A)),
    _TerrainRange('hill', 0.70, 0.79, Color(0xFF607548), Color(0xFF6D8355)),
    _TerrainRange('snow', 0.79, 0.88, Color(0xFFE0E0E0), Color(0xFFF5F5F5)),
    _TerrainRange('lava', 0.88, 1.0, Color(0xFF5A1A1A), Color(0xFF702222)),
  ];

  @override
  void render(Canvas canvas) {
    final offset = absolutePosition;
    final scale = viewScale;
    final screenSize = viewSize;

    final visibleSize = screenSize / scale;
    final topLeft = -offset / scale;
    final bottomRight = topLeft + visibleSize;

    final startX = (topLeft.x / tileSize).floor() * tileSize;
    final startY = (topLeft.y / tileSize).floor() * tileSize;
    final endX = bottomRight.x;
    final endY = bottomRight.y;

    for (double x = startX; x < endX; x += tileSize) {
      for (double y = startY; y < endY; y += tileSize) {
        _renderTile(canvas, x, y, scale);
      }
    }
  }

  void _renderTile(Canvas canvas, double x, double y, double scale) {
    // 🌟 生成噪声 + 拉伸到均匀分布
    final rawNoise = (_noise.fbm(x, y, octaves, frequency, persistence) + 1) / 2;
    final stretched = (rawNoise - 0.3) / 0.4;
    final noiseVal = stretched.clamp(0.0, 1.0);

    // 找到当前区间
    final range = terrainRanges.firstWhere((r) => noiseVal >= r.min && noiseVal < r.max);

    // 算t
    final t = ((noiseVal - range.min) / (range.max - range.min)).clamp(0.0, 1.0);

    // 插值颜色
    final color = Color.lerp(range.colorStart, range.colorEnd, t)!;

    final dx = x * scale;
    final dy = y * scale;
    final size = tileSize * scale;

    // 画渐变色
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(dx, dy, size, size), paint);

    // 贴图（如果加载完成）
    if (_overlayLoaded) {
      _overlayManager.renderIfNeeded(
        canvas: canvas,
        terrainType: range.name,
        noiseVal: noiseVal,
        worldPos: Vector2(x, y),
        scale: scale,
        conditionCheck: (pos) {
          final raw = (_noise.fbm(pos.x, pos.y, octaves, frequency, persistence) + 1) / 2;
          final stretched = (raw - 0.3) / 0.4;
          final adjusted = stretched.clamp(0.0, 1.0);
          final terrainName = terrainRanges.firstWhere(
                  (r) => adjusted >= r.min && adjusted < r.max
          ).name;
          return terrainName == range.name;
        },
      );
    }
  }
}

class _TerrainRange {
  final String name;
  final double min;
  final double max;
  final Color colorStart;
  final Color colorEnd;
  const _TerrainRange(this.name, this.min, this.max, this.colorStart, this.colorEnd);
}
