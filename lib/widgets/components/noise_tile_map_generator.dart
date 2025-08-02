import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/noise_utils.dart';

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize;
  final double smallTileSize;
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;
  final int chunkPixelSize;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();
  Vector2 logicalOffset = Vector2.zero();

  late final NoiseUtils _noiseHeight;
  late final NoiseUtils _noiseHumidity;
  late final NoiseUtils _noiseTemperature;

  final Map<String, ui.Image> _readyChunks = {};
  final Set<String> _generatingChunks = {};
  final List<_PendingChunk> _pendingChunks = [];

  int _chunksGeneratedThisFrame = 0;
  Vector2? _lastEnsureCenter;
  Vector2? _lastEnsureExtra;

  NoiseTileMapGenerator({
    this.tileSize = 4.0,
    this.smallTileSize = 1.0,
    this.seed = 1337,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
    this.chunkPixelSize = 256,
  }) {
    _noiseHeight = NoiseUtils(seed);
    _noiseHumidity = NoiseUtils(seed + 999);
    _noiseTemperature = NoiseUtils(seed - 999);
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

    final paint = ui.Paint()
      ..isAntiAlias = false
      ..filterQuality = ui.FilterQuality.none;

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_$cy';
        final img = _readyChunks[key];
        if (img == null) continue;

        final chunkOrigin = Vector2(cx * chunkPixelSize.toDouble(), cy * chunkPixelSize.toDouble());
        final paintOffset = chunkOrigin - logicalOffset;

        final dx = (paintOffset.x * scale).floorToDouble();
        final dy = (paintOffset.y * scale).floorToDouble();
        final dw = (chunkPixelSize * scale).ceilToDouble();
        final dh = (chunkPixelSize * scale).ceilToDouble();

        final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        final dst = ui.Rect.fromLTWH(dx, dy, dw, dh);

        canvas.drawImageRect(img, src, dst, paint);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _chunksGeneratedThisFrame = 0;
    final pending = List<_PendingChunk>.from(_pendingChunks);
    for (final p in pending) {
      if (_chunksGeneratedThisFrame >= 2) break;
      _pendingChunks.remove(p);
      _generatingChunks.add(p.key);
      _chunksGeneratedThisFrame++;

      _generateChunkImage(p.cx, p.cy).then((img) {
        _readyChunks[p.key] = img;
        _generatingChunks.remove(p.key);
      });
    }
  }

  Future<ui.Image> _generateChunkImage(int cx, int cy) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final extra = tileSize;
    final startX = -extra;
    final startY = -extra;
    final endX = chunkPixelSize + extra;
    final endY = chunkPixelSize + extra;

    final originX = cx * chunkPixelSize.toDouble();
    final originY = cy * chunkPixelSize.toDouble();

    for (double x = startX; x < endX; x += tileSize) {
      for (double y = startY; y < endY; y += tileSize) {
        _renderAdaptiveTile(
          canvas,
          originX + x,
          originY + y,
          tileSize,
          Offset(-originX, -originY),
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(chunkPixelSize, chunkPixelSize);
  }

  void _renderAdaptiveTile(ui.Canvas canvas, double wx, double wy, double size, Offset localOffset) {
    final types = <String>{};
    for (double dx in [0, size]) {
      for (double dy in [0, size]) {
        types.add(_getTerrainAt(wx + dx, wy + dy).type);
      }
    }
    types.add(_getTerrainAt(wx + size / 2, wy + size / 2).type);

    if (types.length == 1 || size <= smallTileSize) {
      final c = _getTerrainAt(wx + size / 2, wy + size / 2).color;
      final dx = (wx + localOffset.dx).floorToDouble();
      final dy = (wy + localOffset.dy).floorToDouble();
      final pxSize = size.ceilToDouble();

      canvas.drawRect(
        ui.Rect.fromLTWH(dx, dy, pxSize, pxSize),
        ui.Paint()
          ..color = c
          ..isAntiAlias = false,
      );
    } else {
      final half = size / 2;
      _renderAdaptiveTile(canvas, wx, wy, half, localOffset);
      _renderAdaptiveTile(canvas, wx + half, wy, half, localOffset);
      _renderAdaptiveTile(canvas, wx, wy + half, half, localOffset);
      _renderAdaptiveTile(canvas, wx + half, wy + half, half, localOffset);
    }
  }

  Future<void> ensureChunksForView({
    required Vector2 center,
    required Vector2 extra,
    bool forceImmediate = false,
  }) async {
    final roundedCenter = Vector2(center.x.roundToDouble(), center.y.roundToDouble());

    double extraArea = extra.x * extra.y;
    double? lastArea;
    if (_lastEnsureCenter != null && _lastEnsureExtra != null) {
      lastArea = _lastEnsureExtra!.x * _lastEnsureExtra!.y;
    }

    if (_lastEnsureCenter != null &&
        (_lastEnsureCenter! - roundedCenter).length < 1 &&
        lastArea != null &&
        (extraArea - lastArea).abs() < 1024) {
      return;
    }

    _lastEnsureCenter = roundedCenter;
    _lastEnsureExtra = extra.clone();

    final topLeft = roundedCenter - extra / 2;
    final bottomRight = roundedCenter + extra / 2;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    final futures = <Future<ui.Image>>[];

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_$cy';
        if (_readyChunks.containsKey(key) || _generatingChunks.contains(key)) continue;

        if (forceImmediate) {
          _generatingChunks.add(key);
          futures.add(_generateChunkImage(cx, cy).then((img) {
            _readyChunks[key] = img;
            _generatingChunks.remove(key);
            return img;
          }));
        } else {
          if (_pendingChunks.any((p) => p.key == key)) continue;
          _pendingChunks.add(_PendingChunk(cx, cy, key));
        }
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  ({String type, ui.Color color}) _getTerrainAt(double nx, double ny) {
    final h1 = (_noiseHeight.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final h2 = (_noiseHumidity.fbm(nx + 1e14, ny + 1e14, octaves, frequency, persistence) + 1) / 2;
    final h3 = (_noiseTemperature.fbm(nx - 1e14, ny - 1e14, octaves, frequency, persistence) + 1) / 2;

    final mixed = (h1 * 0.4 + h2 * 0.3 + h3 * 0.3).clamp(0, 1);

    if (mixed < 0.4 || mixed > 0.6) {
      return (type: 'shallow_ocean', color: const ui.Color(0xFF4FA3C7));
    }

    final normalized = (mixed - 0.4) / 0.2;

    final terrains = [
      ('snow', const ui.Color(0xFFEFEFEF)),
      ('grass', const ui.Color(0xFF9BCB75)),
      ('rock', const ui.Color(0xFF6D6A5F)),
      ('forest', const ui.Color(0xFF3B5F4B)),
      ('flower_field', const ui.Color(0xFFCCC19B)),
      ('shallow_ocean', const ui.Color(0xFF4FA3C7)),
      ('beach', const ui.Color(0xFFEAD7B6)),
      ('volcanic', const ui.Color(0xFF7E3B3B)),
    ];

    final index = (normalized * terrains.length).floor().clamp(0, terrains.length - 1);
    final (type, baseColor) = terrains[index];
    final hsl = HSLColor.fromColor(baseColor);

    final brightnessOffset = _getBrightnessOffsetForY(ny);

    final adjustedColor = hsl
        .withLightness((hsl.lightness + brightnessOffset).clamp(0.0, 1.0))
        .toColor();

    return (type: type, color: adjustedColor);
  }

  double _getBrightnessOffsetForY(double ny) {
    const segmentHeight = 200;
    const groupSize = 100;
    const offsetRange = 0.1; // 总亮度变化范围（0 ~ 0.02）

    final blockIndex = ny ~/ segmentHeight;
    final localIndex = blockIndex % groupSize;

    // 回文：0 1 2 ... 24 25 24 23 ... 1 0
    final mirroredIndex = localIndex <= groupSize ~/ 2
        ? localIndex
        : groupSize - localIndex;

    final maxIndex = groupSize ~/ 2;
    final step = offsetRange / maxIndex;

    // 从 0 到 offsetRange，再回到 0
    final offset = mirroredIndex * step;

    return offset;
  }

  String getTerrainTypeAtPosition(Vector2 worldPos) {
    return _getTerrainAt(worldPos.x, worldPos.y).type;
  }
}

class _PendingChunk {
  final int cx;
  final int cy;
  final String key;
  _PendingChunk(this.cx, this.cy, this.key);
}
