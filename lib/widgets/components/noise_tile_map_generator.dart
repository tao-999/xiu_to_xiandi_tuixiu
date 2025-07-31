import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';

class _PendingChunk {
  final int cx;
  final int cy;
  final String key;
  _PendingChunk(this.cx, this.cy, this.key);
}

class NoiseTileMapGenerator extends PositionComponent {
  final double tileSize;
  final int seed;
  final double frequency;
  final int octaves;
  final double persistence;
  final double smallTileSize;
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
  })  : assert(chunkPixelSize >= 32 && chunkPixelSize <= 4096),
        assert(tileSize <= chunkPixelSize) {
    _noiseHeight = NoiseUtils(seed);
    _noiseHumidity = NoiseUtils(seed + 999);
    _noiseTemperature = NoiseUtils(seed - 999);
  }

  @override
  Future<void> onLoad() async {}

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
      ..filterQuality = ui.FilterQuality.none; // ✅ 禁止插值采样

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_$cy';
        final img = _readyChunks[key];
        if (img == null) continue;

        final chunkOrigin = Vector2(
          cx * chunkPixelSize.toDouble(),
          cy * chunkPixelSize.toDouble(),
        );
        final paintOffset = chunkOrigin - logicalOffset;

        final dx = (paintOffset.x * scale).floorToDouble(); // ✅ 对齐整像素
        final dy = (paintOffset.y * scale).floorToDouble();
        final dw = (chunkPixelSize * scale).ceilToDouble(); // ✅ 防止出现缝
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

    // 每帧限速生成2个
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

    // ✅ 多画一圈：往外延伸 1 个 tile
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

    // ✅ 生成图像大小仍然是 chunkPixelSize（不变）
    return picture.toImage(chunkPixelSize, chunkPixelSize);
  }

  void _renderAdaptiveTile(
      ui.Canvas canvas,
      double wx,
      double wy,
      double size,
      Offset localOffset,
      ) {
    final types = <String>{};
    for (double dx in [0, size]) {
      for (double dy in [0, size]) {
        types.add(_getTerrainType(wx + dx, wy + dy));
      }
    }
    types.add(_getTerrainType(wx + size / 2, wy + size / 2));

    if (types.length == 1 || size <= smallTileSize) {
      _drawTile(
        canvas,
        wx + size / 2,
        wy + size / 2,
        wx + localOffset.dx,
        wy + localOffset.dy,
        size,
        1.0,
      );
    } else {
      final half = size / 2;
      _renderAdaptiveTile(canvas, wx, wy, half, localOffset);
      _renderAdaptiveTile(canvas, wx + half, wy, half, localOffset);
      _renderAdaptiveTile(canvas, wx, wy + half, half, localOffset);
      _renderAdaptiveTile(canvas, wx + half, wy + half, half, localOffset);
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

    final dx = (screenX * scale).floorToDouble(); // ✅ 保证整像素起点
    final dy = (screenY * scale).floorToDouble();
    final pxSize = (size * scale).ceilToDouble(); // ✅ 保证不漏一像素

    final paint = ui.Paint()
      ..color = color
      ..isAntiAlias = false;

    canvas.drawRect(ui.Rect.fromLTWH(dx, dy, pxSize, pxSize), paint);
  }

  /// 🌟 双模式加载（已修复：全屏后不刷新的问题）
  Future<void> ensureChunksForView({
    required Vector2 center,
    required Vector2 extra,
    bool forceImmediate = false,
  }) async {
    final roundedCenter = Vector2(center.x.roundToDouble(), center.y.roundToDouble());

    // 🌟 新增：记录上次 extra 区域大小
    double extraArea = extra.x * extra.y;
    double? lastArea;
    if (_lastEnsureCenter != null && _lastEnsureExtra != null) {
      lastArea = _lastEnsureExtra!.x * _lastEnsureExtra!.y;
    }

    // ✅ 如果中心变化小，同时 extra 区域几乎没变，则跳过（防抖优化）
    if (_lastEnsureCenter != null &&
        (_lastEnsureCenter! - roundedCenter).length < 1 &&
        lastArea != null &&
        (extraArea - lastArea).abs() < 1024) {
      return;
    }

    _lastEnsureCenter = roundedCenter;
    _lastEnsureExtra = extra.clone(); // 🌟 保存当前区域

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

  String _getTerrainType(double nx, double ny) {
    // 不要repeat了，直接无限平滑
    final h1 = (_noiseHeight.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final h2 = (_noiseHumidity.fbm(nx + 1e14, ny + 1e14, octaves, frequency, persistence) + 1) / 2;
    final h3 = (_noiseTemperature.fbm(nx - 1e14, ny - 1e14, octaves, frequency, persistence) + 1) / 2;

    final mixed = (h1 * 0.4 + h2 * 0.3 + h3 * 0.3).clamp(0, 1);

    // 外部区域通通浅海
    if (mixed < 0.4 || mixed > 0.6) {
      return 'shallow_ocean';
    }

    // 把0.4–0.6映射到0–1
    final normalized = (mixed - 0.4) / 0.2;

    // 中心区间所有地形
    final terrains = [
      'snow',
      'grass',
      'rock',
      'forest',
      'flower_field',
      'shallow_ocean',
      'beach',
      'volcanic',
    ];

    final interval = 1.0 / terrains.length;
    final index = (normalized / interval).floor().clamp(0, terrains.length - 1);

    return terrains[index];
  }

  double getWaveOffset(double nx, double ny) {
    final raw = (_noiseTemperature.perlin(nx * 0.0005, ny * 0.0005) + 1) / 2;
    return (raw - 0.5) * 0.6;
  }

  /// 不能删！！非常重要！！
  String getTerrainTypeAtPosition(Vector2 worldPos) {
    return _getTerrainType(worldPos.x, worldPos.y);
  }

  ui.Color _getColorForTerrain(String terrain) {
    switch (terrain) {
      case 'shallow_ocean':
        return const ui.Color(0xFF4FA3C7);
      case 'beach':
        return const ui.Color(0xFFEAD7B6);
      case 'grass':
        return const ui.Color(0xFF9BCB75);
      case 'forest':
        return const ui.Color(0xFF4E8B69);
      case 'rock':
        return const ui.Color(0xFF9FA9B3);
      case 'snow':
        return const ui.Color(0xFFEFEFEF);
      case 'flower_field':
        return const ui.Color(0xFFE6E6B3);
      case 'volcanic':
        return const ui.Color(0xFF7E3B3B);
      default:
        return const ui.Color(0xFF9BCB75);
    }
  }
}
