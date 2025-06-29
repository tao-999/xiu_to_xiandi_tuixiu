// lib/widgets/components/noise_tile_map_generator.dart

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize; // 大瓦片尺寸
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;
  final double smallTileSize;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();
  Vector2 logicalOffset = Vector2.zero();

  late final NoiseUtils _noiseHeight;
  late final NoiseUtils _noiseHumidity;
  late final NoiseUtils _noiseTemperature;

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.smallTileSize = 1.0,
    this.seed = 1337,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
  }) {
    _noiseHeight = NoiseUtils(seed);
    _noiseHumidity = NoiseUtils(seed + 999);
    _noiseTemperature = NoiseUtils(seed - 999);
  }

  @override
  void render(Canvas canvas) {
    final scale = viewScale;
    final screenSize = viewSize;

    final visibleSize = screenSize / scale;
    final topLeft = -(screenSize / 2) / scale; // 画布左上角不加偏移
    final bottomRight = topLeft + visibleSize;

    final startX = topLeft.x;
    final startY = topLeft.y;
    final endX = bottomRight.x;
    final endY = bottomRight.y;

    for (double x = startX; x < endX; x += tileSize) {
      for (double y = startY; y < endY; y += tileSize) {
        if (_isEdgeTile(x + logicalOffset.x, y + logicalOffset.y, tileSize)) {
          _renderFineTile(canvas, x, y, tileSize, scale);
        } else {
          _renderCoarseTile(canvas, x, y, tileSize, scale);
        }
      }
    }
  }

  bool _isEdgeTile(double nx, double ny, double size) {
    final Set<String> types = {};
    for (double dx in [0, size]) {
      for (double dy in [0, size]) {
        types.add(_getTerrainType(nx + dx, ny + dy));
      }
    }
    return types.length > 1;
  }

  void _renderCoarseTile(Canvas canvas, double x, double y, double size, double scale) {
    _drawTile(canvas, x + logicalOffset.x, y + logicalOffset.y, x, y, size, scale);
  }

  void _renderFineTile(Canvas canvas, double x, double y, double bigSize, double scale) {
    for (double sx = x; sx < x + bigSize; sx += smallTileSize) {
      for (double sy = y; sy < y + bigSize; sy += smallTileSize) {
        _drawTile(canvas, sx + logicalOffset.x, sy + logicalOffset.y, sx, sy, smallTileSize, scale);
      }
    }
  }

  void _drawTile(Canvas canvas, double nx, double ny, double screenX, double screenY, double size, double scale) {
    final terrain = _getTerrainType(nx, ny);
    final color = _getColorForTerrain(terrain);

    final dx = (screenX * scale).roundToDouble();
    final dy = (screenY * scale).roundToDouble();
    final pxSize = (size * scale).roundToDouble();

    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(dx, dy, pxSize, pxSize), paint);
  }

  String _getTerrainType(double nx, double ny) {
    final h1 = (_noiseHeight.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final h2 = (_noiseHumidity.fbm(nx + 10000, ny + 10000, octaves, frequency, persistence) + 1) / 2;

    final hMix = (h1 + h2) / 2;
    final wave = (sin(hMix * pi * 2 - pi / 2) + 1) / 2;

    if (wave < 0.05) return 'deep_ocean';
    if (wave < 0.10) return 'shallow_ocean';
    if (wave < 0.15) return 'beach';
    if (wave < 0.40) return 'grass';
    if (wave < 0.60) return 'forest';
    if (wave < 0.70) return 'snow';
    if (wave < 0.80) return 'forest';
    if (wave < 0.88) return 'grass';
    if (wave < 0.93) return 'mud';
    if (wave < 0.97) return 'beach';
    if (wave < 0.99) return 'shallow_ocean';
    return 'grass';
  }

  Color _getColorForTerrain(String terrain) {
    switch (terrain) {
      case 'deep_ocean':
        return Color(0xFF001F2D);
      case 'shallow_ocean':
        return Color(0xFF3E9DBF);
      case 'beach':
        return Color(0xFFEED9A0);
      case 'grass':
        return Color(0xFF6C9A5E);
      case 'forest':
        return Color(0xFF2E5530);
      case 'snow':
        return Color(0xFFE0E0E0);
      case 'mud':
        return Color(0xFF4A3628);
      default:
        return Color(0xFF6C9A5E);
    }
  }

  /// 给外部用
  String getTerrainTypeAtPosition(Vector2 worldPos) {
    return _getTerrainType(worldPos.x, worldPos.y);
  }
}
