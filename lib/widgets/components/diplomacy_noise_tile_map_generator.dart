import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/noise_utils.dart';

class DiplomacyNoiseTileMapGenerator extends PositionComponent {
  static const int chunkPixelSize = 512;

  final double tileSize;
  final double smallTileSize;

  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;

  final double mapWidth = double.infinity;
  final double mapHeight = double.infinity;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();
  Vector2 logicalOffset = Vector2.zero();

  final int maxRecursionDepth = 12;

  final Map<String, ui.Image> _readyChunkImages = {};
  final List<_PendingChunk> _pendingChunks = [];
  int _chunksGeneratedThisFrame = 0;

  final NoiseUtils _noiseHeight;

  Vector2? _lastEnsureCenter;

  DiplomacyNoiseTileMapGenerator({
    this.tileSize = 64.0,
    this.smallTileSize = 4.0,
    this.seed = 2024,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
  }) : _noiseHeight = NoiseUtils(seed);

  @override
  Future<void> onLoad() async {}

  @override
  void render(ui.Canvas canvas) {
    final screenSize = viewSize;
    final visibleSize = screenSize;

    final topLeft = logicalOffset;
    final bottomRight = logicalOffset + visibleSize;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = ((bottomRight.x) / chunkPixelSize).ceil() - 1;
    final endChunkY = ((bottomRight.y) / chunkPixelSize).ceil() - 1;

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();
        final key = '${cx}_${cy}';

        final img = _readyChunkImages[key];
        if (img != null) {
          final dx = ((chunkLeft - logicalOffset.x) * viewScale).floorToDouble();
          final dy = ((chunkTop - logicalOffset.y) * viewScale).floorToDouble();

          final dstRect = ui.Rect.fromLTWH(
            dx,
            dy,
            (img.width * viewScale).ceilToDouble(),
            (img.height * viewScale).ceilToDouble(),
          );

          canvas.drawImageRect(
            img,
            ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            dstRect,
            ui.Paint()..isAntiAlias = false,
          );
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _chunksGeneratedThisFrame = 0;
    final pendingToGenerate = List<_PendingChunk>.from(_pendingChunks);
    for (final pending in pendingToGenerate) {
      if (_chunksGeneratedThisFrame >= 2) break;

      _pendingChunks.remove(pending);
      _chunksGeneratedThisFrame++;

      _generateChunkImage(pending.cx, pending.cy, pending.key).then((img) {
        _readyChunkImages[pending.key] = img;
      });
    }
  }

  Future<ui.Image> _generateChunkImage(int cx, int cy, String key) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final originX = cx * chunkPixelSize.toDouble();
    final originY = cy * chunkPixelSize.toDouble();

    for (double x = 0; x < chunkPixelSize; x += tileSize) {
      for (double y = 0; y < chunkPixelSize; y += tileSize) {
        final wx = originX + x;
        final wy = originY + y;

        _renderAdaptiveTile(
          canvas,
          wx,
          wy,
          tileSize,
          ui.Offset(-originX, -originY),
          0,
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
      ui.Offset offset,
      int depth,
      ) {
    if (depth > maxRecursionDepth) return;

    final levels = [
      _getHeightLevel(_getNoiseValue(wx, wy)),
      _getHeightLevel(_getNoiseValue(wx + size, wy)),
      _getHeightLevel(_getNoiseValue(wx, wy + size)),
      _getHeightLevel(_getNoiseValue(wx + size, wy + size)),
      _getHeightLevel(_getNoiseValue(wx + size / 2, wy + size / 2)),
    ];

    final isUniform = levels.toSet().length == 1 || size <= smallTileSize;
    if (isUniform) {
      final v = _getNoiseValue(wx + size / 2, wy + size / 2);
      final color = _getColorForHeight(v);
      _drawRect(canvas, wx, wy, size, offset, color);
    } else {
      final half = size / 2;
      _renderAdaptiveTile(canvas, wx, wy, half, offset, depth + 1);
      _renderAdaptiveTile(canvas, wx + half, wy, half, offset, depth + 1);
      _renderAdaptiveTile(canvas, wx, wy + half, half, offset, depth + 1);
      _renderAdaptiveTile(canvas, wx + half, wy + half, half, offset, depth + 1);
    }
  }

  void _drawRect(
      ui.Canvas canvas,
      double wx,
      double wy,
      double size,
      ui.Offset offset,
      ui.Color color,
      ) {
    final dx = (wx + offset.dx).floorToDouble();      // ✅ 整像素起点
    final dy = (wy + offset.dy).floorToDouble();
    final w = size.ceilToDouble();                    // ✅ 整数宽高
    final h = size.ceilToDouble();

    final rect = ui.Rect.fromLTWH(dx, dy, w, h);

    final paint = ui.Paint()
      ..color = color
      ..isAntiAlias = false;                          // ✅ 禁用抗锯齿

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
    if (!worldPos.x.isFinite || !worldPos.y.isFinite) {
      debugPrint('❌ getTerrainTypeAtPosition: 非法坐标 $worldPos');
      return null;
    }

    if (worldPos.x < 0 || worldPos.y < 0) return null;

    final value = _getNoiseValue(worldPos.x, worldPos.y);
    return _getTerrainType(value);
  }

  String _getTerrainType(double value) {
    if (value < 0) return 'ocean';
    if (value < 0.2) return 'plain';
    if (value < 0.4) return 'hill';
    return 'mountain';
  }

  Future<void> ensureChunksForView({
    required Vector2 center,
    required Vector2 extra,
    bool forceImmediate = false,
  }) async {
    final roundedCenter = Vector2(center.x.roundToDouble(), center.y.roundToDouble());
    final scale = viewScale;
    final visibleSize = viewSize / scale;

    final topLeft = roundedCenter - visibleSize / 2 - extra / 2;
    final bottomRight = roundedCenter + visibleSize / 2 + extra / 2;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = ((bottomRight.x) / chunkPixelSize).ceil() - 1;
    final endChunkY = ((bottomRight.y) / chunkPixelSize).ceil() - 1;

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_${cy}';
        if (_readyChunkImages.containsKey(key)) continue;
        if (!_pendingChunks.any((e) => e.key == key)) {
          _pendingChunks.add(_PendingChunk(cx, cy, key));
        }
      }
    }
  }
}

class _PendingChunk {
  final int cx;
  final int cy;
  final String key;
  _PendingChunk(this.cx, this.cy, this.key);
}
