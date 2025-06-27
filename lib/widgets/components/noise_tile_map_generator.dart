import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';
import '../components/tile_overlay_renderer_manager.dart';

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize; // 不用了，这里用bigTileSize/smallTileSize
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;
  final double smallTileSize;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();

  Vector2 logicalOffset = Vector2.zero();

  late final NoiseUtils _noise;
  late final TileOverlayRendererManager _overlayManager;

  bool _overlayLoaded = false;

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.smallTileSize = 1.0,
    this.seed = 1337,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
  }) {
    _noise = NoiseUtils(seed);
    _overlayManager = TileOverlayRendererManager(seed: seed);

    _overlayManager.register(terrainType: 'forest', tileType: 'tree');
  }

  @override
  Future<void> onLoad() async {
    await _overlayManager.loadAllAssets();
    _overlayLoaded = true;
  }

  final List<_TerrainRange> terrainRanges = [
    _TerrainRange('deep_ocean', 0.0, 0.18, Color(0xFF001F2D), Color(0xFF00334D)),
    _TerrainRange('shallow_ocean', 0.18, 0.32, Color(0xFF3E9DBF), Color(0xFF4DA6C3)),
    _TerrainRange('beach', 0.32, 0.42, Color(0xFFEED9A0), Color(0xFFF3E2B7)),
    _TerrainRange('grass', 0.42, 0.52, Color(0xFF6C9A5E), Color(0xFF77A865)),
    _TerrainRange('mud', 0.52, 0.61, Color(0xFF4A3628), Color(0xFF5C4431)),
    _TerrainRange('forest', 0.61, 0.70, Color(0xFF2E5530), Color(0xFF3A663A)),
    _TerrainRange('hill', 0.70, 0.79, Color(0xFF607548), Color(0xFF6D8355)),
    _TerrainRange('snow', 0.79, 0.88, Color(0xFFE0E0E0), Color(0xFFF5F5F5)),
    _TerrainRange('lava', 0.88, 1.01, Color(0xFF5A1A1A), Color(0xFF702222)),
  ];

  @override
  void render(Canvas canvas) {
    final scale = viewScale;
    final screenSize = viewSize;

    final visibleSize = screenSize / scale;
    final topLeft = -(screenSize / 2) / scale;
    final bottomRight = topLeft + visibleSize;

    final startX = topLeft.x;
    final startY = topLeft.y;
    final endX = bottomRight.x;
    final endY = bottomRight.y;

    // 注意：bigTileSize不再写const，直接用 tileSize 和 smallTileSize
    final double bigTileSize = tileSize; // tileSize是构造函数参数

    for (double x = startX; x < endX; x += bigTileSize) {
      for (double y = startY; y < endY; y += bigTileSize) {
        if (_isEdgeTile(x, y, bigTileSize)) {
          _renderFineTile(canvas, x, y, bigTileSize, scale);
        } else {
          _renderCoarseTile(canvas, x, y, bigTileSize, scale);
        }
      }
    }
  }

  bool _isEdgeTile(double x, double y, double tileSize) {
    final List<String> types = [];
    for (double dx in [0, tileSize]) {
      for (double dy in [0, tileSize]) {
        final nx = x + dx + logicalOffset.x;
        final ny = y + dy + logicalOffset.y;
        final noiseVal = (_noise.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
        final stretched = (noiseVal - 0.3) / 0.4;
        final clamped = stretched.clamp(0.0, 1.0);
        final terrain = terrainRanges.firstWhere((r) => clamped >= r.min && clamped < r.max).name;
        types.add(terrain);
      }
    }
    return types.toSet().length > 1;
  }

  void _drawTile({
    required Canvas canvas,
    required double worldX,
    required double worldY,
    required double screenX,
    required double screenY,
    required double tileSize,
    required double scale,
    required _TerrainRange range,
    required double noiseVal,
  }) {
    // ✅ 🌈 恢复渐变色
    final t = ((noiseVal - range.min) / (range.max - range.min)).clamp(0.0, 1.0);
    final color = Color.lerp(range.colorStart, range.colorEnd, t)!;

    final dx = screenX * scale;
    final dy = screenY * scale;
    final size = tileSize * scale;

    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(dx, dy, size, size), paint);

    if (_overlayLoaded) {
      _overlayManager.renderIfNeeded(
        canvas: canvas,
        terrainType: range.name,
        noiseVal: noiseVal,
        worldPos: Vector2(worldX, worldY),
        scale: scale,
        cameraOffset: logicalOffset,
        conditionCheck: (pos) {
          final raw = (_noise.fbm(pos.x, pos.y, octaves, frequency, persistence) + 1) / 2;
          final stretched = (raw - 0.3) / 0.4;
          final adjusted = stretched.clamp(0.0, 1.0);
          final terrainName = terrainRanges.firstWhere(
                (r) => adjusted >= r.min && adjusted < r.max,
          ).name;
          return terrainName == range.name;
        },
      );
    }
  }

  void _renderCoarseTile(Canvas canvas, double x, double y, double tileSize, double scale) {
    final nx = x + logicalOffset.x;
    final ny = y + logicalOffset.y;
    final rawNoise = (_noise.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final stretched = (rawNoise - 0.3) / 0.4;
    final noiseVal = stretched.clamp(0.0, 1.0);
    final range = terrainRanges.firstWhere((r) => noiseVal >= r.min && noiseVal < r.max);

    _drawTile(
      canvas: canvas,
      worldX: nx,
      worldY: ny,
      screenX: x,
      screenY: y,
      tileSize: tileSize,
      scale: scale,
      range: range,
      noiseVal: noiseVal,
    );
  }

  void _renderFineTile(Canvas canvas, double x, double y, double bigTileSize, double scale) {
    for (double sx = x; sx < x + bigTileSize; sx += smallTileSize) {
      for (double sy = y; sy < y + bigTileSize; sy += smallTileSize) {
        final nx = sx + logicalOffset.x;
        final ny = sy + logicalOffset.y;
        final rawNoise = (_noise.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
        final stretched = (rawNoise - 0.3) / 0.4;
        final noiseVal = stretched.clamp(0.0, 1.0);
        final range = terrainRanges.firstWhere((r) => noiseVal >= r.min && noiseVal < r.max);

        _drawTile(
          canvas: canvas,
          worldX: nx,
          worldY: ny,
          screenX: sx,
          screenY: sy,
          tileSize: smallTileSize,
          scale: scale,
          range: range,
          noiseVal: noiseVal,
        );
      }
    }
  }

  String getTerrainTypeAtPosition(Vector2 worldPos) {
    final rawNoise = (_noise.fbm(worldPos.x, worldPos.y, octaves, frequency, persistence) + 1) / 2;
    final stretched = (rawNoise - 0.3) / 0.4;
    final noiseVal = stretched.clamp(0.0, 1.0);

    final range = terrainRanges.firstWhere(
          (r) => noiseVal >= r.min && noiseVal < r.max,
      orElse: () => terrainRanges.last, // 万一没匹配到，默认最后一个
    );
    return range.name;
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
