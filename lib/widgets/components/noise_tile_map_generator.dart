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

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.seed = 1337,
    this.frequency = 0.005,
    this.octaves = 4,
    this.persistence = 0.5,
  }) {
    _noise = NoiseUtils(seed);
    _overlayManager = TileOverlayRendererManager(seed: seed);

    // ✅ 注册地形类型 → 贴图类型
    _overlayManager.register(terrainType: 'forest', tileType: 'tree');
  }

  @override
  Future<void> onLoad() async {
    await _overlayManager.loadAllAssets(); // ✅ 加载所有贴图资源
  }

  String _getTerrainType(double val) {
    if (val < 0.15) return 'deep_ocean';
    if (val < 0.3) return 'shallow_ocean';
    if (val < 0.4) return 'beach';
    if (val < 0.52) return 'grass';
    if (val < 0.58) return 'mud';
    if (val < 0.65) return 'forest';
    if (val < 0.75) return 'hill';
    if (val < 0.9) return 'snow';
    return 'lava';
  }

  final Map<String, Paint> terrainPaints = {
    'deep_ocean': Paint()..color = const Color(0xFF00334D),     // 🌊 深海幽蓝
    'shallow_ocean': Paint()..color = const Color(0xFF66CCFF),  // 🏝️ 浅滩亮蓝
    'beach': Paint()..color = const Color(0xFFEEDC82),
    'grass': Paint()..color = const Color(0xFF88C070),
    'mud': Paint()..color = const Color(0xFF70543E),
    'forest': Paint()..color = const Color(0xFF3C803C),
    'hill': Paint()..color = const Color(0xFF558844),
    'snow': Paint()..color = const Color(0xFFE0E0E0),
    'lava': Paint()..color = const Color(0xFF8B0000),
  };

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
    final noiseVal = (_noise.fbm(x, y, octaves, frequency, persistence) + 1) / 2;
    final terrain = _getTerrainType(noiseVal);

    final dx = x * scale;
    final dy = y * scale;
    final size = tileSize * scale;

    // ✅ 绘制地形底色
    final paint = terrainPaints[terrain]!;
    canvas.drawRect(Rect.fromLTWH(dx, dy, size, size), paint);

    // ✅ 渲染贴图（如果有注册过）
    _overlayManager.renderIfNeeded(
      canvas: canvas,
      terrainType: terrain,
      noiseVal: noiseVal,
      worldPos: Vector2(x, y),
      scale: scale,
      conditionCheck: (pos) {
        final val = (_noise.fbm(pos.x, pos.y, octaves, frequency, persistence) + 1) / 2;
        return _getTerrainType(val) == terrain;
      },
    );
  }
}
