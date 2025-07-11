import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';

class DiplomacyNoiseTileMapGenerator extends PositionComponent {
  final double tileSize;
  final double smallTileSize;
  final int chunkPixelSize;
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;

  static const double maxMapSize = 2500.0;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();
  Vector2 logicalOffset = Vector2.zero();

  final Map<String, ui.Image?> _chunkCache = {};
  final NoiseUtils _noiseHeight;

  DiplomacyNoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.smallTileSize = 1.0,
    this.chunkPixelSize = 512,
    this.seed = 2024,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
  })  : assert(chunkPixelSize >= 32 && chunkPixelSize <= 4096),
        assert(tileSize <= chunkPixelSize),
        _noiseHeight = NoiseUtils(seed);

  @override
  Future<void> onLoad() async {
    // 不预生成
  }

  @override
  void render(ui.Canvas canvas) {
    final scale = 1.0;
    final screenSize = viewSize;
    final visibleSize = screenSize;

    // ❗ 直接用逻辑offset，不要再对齐
    final topLeft = logicalOffset;
    final bottomRight = logicalOffset + visibleSize;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    final keepKeys = <String>{};

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();

        // 🌟去掉死边界约束
        final key = '${cx}_${cy}';
        keepKeys.add(key);

        if (!_chunkCache.containsKey(key)) {
          _chunkCache[key] = null;
          _generateChunkImage(cx, cy).then((img) {
            _chunkCache[key] = img;
          });
        }
      }
    }

    // 清理不用的
    _chunkCache.removeWhere((k, _) => !keepKeys.contains(k));

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();

        final key = '${cx}_${cy}';
        final img = _chunkCache[key];
        if (img != null) {
          final offsetX = (chunkLeft - logicalOffset.x);
          final offsetY = (chunkTop - logicalOffset.y);
          canvas.drawImage(img, Offset(offsetX, offsetY), ui.Paint());
        }
      }
    }
  }

  Future<ui.Image> _generateChunkImage(int cx, int cy) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final originX = cx * chunkPixelSize.toDouble();
    final originY = cy * chunkPixelSize.toDouble();

    for (double x = 0; x < chunkPixelSize; x += tileSize) {
      for (double y = 0; y < chunkPixelSize; y += tileSize) {
        final wx = originX + x;
        final wy = originY + y;

        if (wx.abs() >= maxMapSize || wy.abs() >= maxMapSize) continue;

        _renderAdaptiveTile(
          canvas,
          wx,
          wy,
          tileSize,
          Offset(-originX, -originY),
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(chunkPixelSize, chunkPixelSize);
  }

  void _renderAdaptiveTile(
      ui.Canvas canvas,
      double wx,
      double wy,
      double size,
      Offset offset,
      ) {
    if ((wx + size).abs() >= maxMapSize || (wy + size).abs() >= maxMapSize) return;

    final levels = [
      _getHeightLevel(_getNoiseValue(wx, wy)),
      _getHeightLevel(_getNoiseValue(wx + size, wy)),
      _getHeightLevel(_getNoiseValue(wx, wy + size)),
      _getHeightLevel(_getNoiseValue(wx + size, wy + size)),
      _getHeightLevel(_getNoiseValue(wx + size / 2, wy + size / 2)),
    ];

    final isFullSea = levels.every((l) => l == 0);
    if (isFullSea) {
      _drawRect(canvas, wx, wy, size, offset, const ui.Color(0xFF66AACC));
      return;
    }

    final isUniform = levels.toSet().length == 1 || size <= smallTileSize;
    if (isUniform) {
      final v = _getNoiseValue(wx + size / 2, wy + size / 2);
      final color = _getColorForHeight(v);
      _drawRect(canvas, wx, wy, size, offset, color);
    } else {
      final half = size / 2;
      _renderAdaptiveTile(canvas, wx, wy, half, offset);
      _renderAdaptiveTile(canvas, wx + half, wy, half, offset);
      _renderAdaptiveTile(canvas, wx, wy + half, half, offset);
      _renderAdaptiveTile(canvas, wx + half, wy + half, half, offset);
    }
  }

  void _drawRect(
      ui.Canvas canvas,
      double wx,
      double wy,
      double size,
      Offset offset,
      ui.Color color,
      ) {
    final dx = wx + offset.dx;
    final dy = wy + offset.dy;
    final rect = ui.Rect.fromLTWH(dx, dy, size, size);
    final paint = ui.Paint()..color = color;
    canvas.drawRect(rect, paint);
  }

  double _getNoiseValue(double nx, double ny) =>
      _noiseHeight.fbm(nx, ny, octaves, frequency, persistence);

  int _getHeightLevel(double value) {
    if (value < 0) return 0;
    if (value < 0.2) return 1;
    if (value < 0.4) return 2;
    return 3;
  }

  ui.Color _getColorForHeight(double value) {
    if (value < 0) return const ui.Color(0xFF66AACC);
    if (value < 0.2) return const ui.Color(0xFF88C07A);
    if (value < 0.4) return const ui.Color(0xFF4E8B69);
    return const ui.Color(0xFFCCCCCC);
  }

  String? getTerrainTypeAtPosition(Vector2 worldPos) {
    if (worldPos.x.abs() >= maxMapSize || worldPos.y.abs() >= maxMapSize) return null;
    final value = _getNoiseValue(worldPos.x, worldPos.y);
    return _getTerrainType(value);
  }

  String _getTerrainType(double value) {
    if (value < 0) return 'ocean';
    if (value < 0.2) return 'plain';
    if (value < 0.4) return 'hill';
    return 'mountain';
  }

  /// 🌟同步生成一个指定中心、指定额外范围的chunk
  Future<void> ensureChunksForView({
    required Vector2 center,
    required Vector2 extra,
  }) async {
    final scale = viewScale;
    final visibleSize = viewSize / scale;

    final topLeft = center - visibleSize / 2 - extra / 2;
    final bottomRight = center + visibleSize / 2 + extra / 2;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();

        if (chunkLeft.abs() >= maxMapSize || chunkTop.abs() >= maxMapSize) continue;

        final key = '${cx}_${cy}';
        if (!_chunkCache.containsKey(key)) {
          _chunkCache[key] = await _generateChunkImage(cx, cy);
        }
      }
    }
  }

}
