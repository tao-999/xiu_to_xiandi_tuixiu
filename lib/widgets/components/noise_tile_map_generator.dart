// lib/widgets/components/noise_tile_map_generator.dart

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize;        // 大瓦片尺寸
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;
  final double smallTileSize;   // 小瓦片尺寸
  final int chunkPixelSize;     // 每个chunk的像素大小

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();
  Vector2 logicalOffset = Vector2.zero();

  late final NoiseUtils _noiseHeight;
  late final NoiseUtils _noiseHumidity;
  late final NoiseUtils _noiseTemperature;

  final Map<String, ui.Image?> _chunkCache = {};

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.smallTileSize = 1.0,
    this.seed = 1337,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
    this.chunkPixelSize = 256,
  })  : assert(chunkPixelSize >= 32 && chunkPixelSize <= 4096, 'chunkPixelSize必须合理'),
        assert(tileSize <= chunkPixelSize, 'tileSize不能比chunkPixelSize大') {
    _noiseHeight = NoiseUtils(seed);
    _noiseHumidity = NoiseUtils(seed + 999);
    _noiseTemperature = NoiseUtils(seed - 999);
  }

  @override
  Future<void> onLoad() async {
    // 🚀 首屏预生成中心区域，避免黑屏
    final startChunkX = -1;
    final startChunkY = -1;
    final endChunkX = 2;
    final endChunkY = 2;
    for (int cx = startChunkX; cx < endChunkX; cx++) {
      for (int cy = startChunkY; cy < endChunkY; cy++) {
        final key = '${cx}_$cy';
        _chunkCache[key] = await _generateChunkImage(cx, cy);
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final scale = viewScale;
    final screenSize = viewSize;

    final visibleSize = screenSize / scale;
    final topLeft = -(screenSize / 2) / scale + logicalOffset;
    final bottomRight = topLeft + visibleSize;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    // 🚀 提前加载范围：每边多1块
    final preloadStartX = startChunkX - 1;
    final preloadStartY = startChunkY - 1;
    final preloadEndX = endChunkX + 1;
    final preloadEndY = endChunkY + 1;

    // 🟢 先批量触发生成（包含预加载区域）
    for (int cx = preloadStartX; cx < preloadEndX; cx++) {
      for (int cy = preloadStartY; cy < preloadEndY; cy++) {
        final key = '${cx}_$cy';
        if (!_chunkCache.containsKey(key)) {
          // 先放null防止重复生成
          _chunkCache[key] = null;
          _generateChunkImage(cx, cy).then((img) {
            _chunkCache[key] = img;
          });
        }
      }
    }

    // 🟢 再绘制可视区域（只画视口范围）
    for (int cx = startChunkX; cx < endChunkX; cx++) {
      for (int cy = startChunkY; cy < endChunkY; cy++) {
        final key = '${cx}_$cy';
        final chunkOrigin = Vector2(cx * chunkPixelSize.toDouble(), cy * chunkPixelSize.toDouble());

        final paintOffset = chunkOrigin - logicalOffset;
        final dx = (paintOffset.x * scale).floorToDouble();
        final dy = (paintOffset.y * scale).floorToDouble();

        final img = _chunkCache[key];
        if (img != null) {
          canvas.drawImage(img, ui.Offset(dx, dy), ui.Paint());
        }
      }
    }
  }

  /// 🌟 生成单个chunk的Image
  Future<ui.Image> _generateChunkImage(int cx, int cy) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final originX = cx * chunkPixelSize.toDouble();
    final originY = cy * chunkPixelSize.toDouble();

    for (double x = 0; x < chunkPixelSize; x += tileSize) {
      for (double y = 0; y < chunkPixelSize; y += tileSize) {
        final wx = originX + x;
        final wy = originY + y;

        if (_isEdgeTile(wx, wy, tileSize)) {
          _renderFineTile(canvas, wx, wy, tileSize, 1.0, localOffset: Offset(-originX, -originY));
        } else {
          _renderCoarseTile(canvas, wx, wy, tileSize, 1.0, localOffset: Offset(-originX, -originY));
        }
      }
    }

    final picture = recorder.endRecording();
    return await picture.toImage(chunkPixelSize, chunkPixelSize);
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

  void _renderCoarseTile(
      ui.Canvas canvas,
      double wx,
      double wy,
      double size,
      double scale, {
        required Offset localOffset,
      }) {
    _drawTile(canvas, wx, wy, wx + localOffset.dx, wy + localOffset.dy, size, scale);
  }

  void _renderFineTile(
      ui.Canvas canvas,
      double wx,
      double wy,
      double bigSize,
      double scale, {
        required Offset localOffset,
      }) {
    for (double sx = wx; sx < wx + bigSize; sx += smallTileSize) {
      for (double sy = wy; sy < wy + bigSize; sy += smallTileSize) {
        _drawTile(canvas, sx, sy, sx + localOffset.dx, sy + localOffset.dy, smallTileSize, scale);
      }
    }
  }

  void _drawTile(
      ui.Canvas canvas,
      double nx,
      double ny,
      double screenX,
      double screenY,
      double size,
      double scale,
      ) {
    final terrain = _getTerrainType(nx, ny);
    final color = _getColorForTerrain(terrain);

    final dx = (screenX * scale).roundToDouble();
    final dy = (screenY * scale).roundToDouble();
    final pxSize = (size * scale).roundToDouble();

    final paint = ui.Paint()..color = color;
    canvas.drawRect(ui.Rect.fromLTWH(dx, dy, pxSize, pxSize), paint);
  }

  String getTerrainTypeAtPosition(Vector2 worldPos) {
    return _getTerrainType(worldPos.x, worldPos.y);
  }

  double getWaveOffset(double nx, double ny) {
    // 用一层 Perlin 噪声做平滑偏移
    final raw = (_noiseTemperature.perlin(nx * 0.0005, ny * 0.0005) + 1) / 2;
    // raw = 0~1
    // 映射到 -0.3 ~ +0.3
    return (raw - 0.5) * 0.6;
  }

  String _getTerrainType(double nx, double ny) {
    final h1 = (_noiseHeight.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final h2 = (_noiseHumidity.fbm(nx + 1e14, ny + 1e14, octaves, frequency, persistence) + 1) / 2;
    final h3 = (_noiseTemperature.fbm(nx - 1e14, ny - 1e14, octaves, frequency, persistence) + 1) / 2;

    final mixed = (h1 * 0.4 + h2 * 0.3 + h3 * 0.3).clamp(0,1);

    // 极限拉伸
    double wave = ((mixed - 0.4) / 0.2).clamp(0,1);

    // 🌈这里平移波峰
    final offset = getWaveOffset(nx, ny);
    wave = (wave + offset).clamp(0,1);

    if (wave < 0.08) return 'shallow_ocean'; // 合并深海
    if (wave < 0.13) return 'beach';
    if (wave < 0.25) return 'mud';
    if (wave < 0.40) return 'grass';
    if (wave < 0.50) return 'forest';
    if (wave < 0.60) return 'rock';
    if (wave < 0.70) return 'snow';
    if (wave < 0.80) return 'flower_field';
    if (wave < 0.88) return 'volcanic';
    if (wave < 0.94) return 'glacier';
    return 'shallow_ocean';
  }


  ui.Color _getColorForTerrain(String terrain) {
    switch (terrain) {
      case 'deep_ocean':
        return const ui.Color(0xFF223344); // 深海蓝
      case 'shallow_ocean':
        return const ui.Color(0xFF447799); // 浅海蓝
      case 'beach':
        return const ui.Color(0xFFDDCCAA); // 沙滩
      case 'mud':
        return const ui.Color(0xFF8B6F4A); // 泥地
      case 'grass':
        return const ui.Color(0xFF88A76C); // 草地
      case 'forest':
        return const ui.Color(0xFF506C44); // 森林
      case 'rock':
        return const ui.Color(0xFFAAAAAA); // 石地
      case 'snow':
        return const ui.Color(0xFFEAEAEA); // 雪原
      case 'flower_field':
        return const ui.Color(0xFFB8D1B0); // 花田
      case 'volcanic':
        return const ui.Color(0xFF774444); // 火山
      case 'glacier':
        return const ui.Color(0xFFCFE5F5); // 冰川
      case 'black_zone':
        return const ui.Color(0xFF000000); // 黑色禁区
      default:
        return const ui.Color(0xFF88A76C); // 默认草地
    }
  }
}
