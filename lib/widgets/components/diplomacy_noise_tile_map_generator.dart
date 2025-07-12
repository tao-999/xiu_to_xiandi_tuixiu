import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../utils/noise_utils.dart';

class _ChunkCacheEntry {
  DateTime lastAccess;
  _ChunkCacheEntry() : lastAccess = DateTime.now();
}

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

  final int maxChunkCache = 128;
  final int maxRecursionDepth = 12; // 🚀调低递归深度

  final Map<String, _ChunkCacheEntry> _chunkCache = {};
  final Map<String, ui.Image> _readyChunkImages = {};
  final NoiseUtils _noiseHeight;

  Vector2? _lastEnsureCenter;

  // 分帧加载队列
  final List<_PendingChunk> _pendingChunks = [];
  int _chunksGeneratedThisFrame = 0;

  DiplomacyNoiseTileMapGenerator({
    this.tileSize = 64.0,
    this.smallTileSize = 8.0,
    this.chunkPixelSize = 256,
    this.seed = 2024,
    this.frequency = 0.002,
    this.octaves = 4,
    this.persistence = 0.5,
  })  : assert(chunkPixelSize >= 32 && chunkPixelSize <= 4096),
        assert(tileSize <= chunkPixelSize),
        _noiseHeight = NoiseUtils(seed);

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
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    final keepKeys = <String>{};

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_${cy}';
        keepKeys.add(key);

        if (_chunkCache.containsKey(key)) {
          _chunkCache[key]?.lastAccess = DateTime.now();
        }
      }
    }

    // LRU 清理
    if (_chunkCache.length > maxChunkCache) {
      final sortedKeys = _chunkCache.entries.toList()
        ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
      final removeCount = _chunkCache.length - maxChunkCache;
      for (int i = 0; i < removeCount; i++) {
        final key = sortedKeys[i].key;
        final img = _readyChunkImages.remove(key);
        img?.dispose();
        _chunkCache.remove(key);
      }
    }

    _chunkCache.removeWhere((k, v) {
      if (!keepKeys.contains(k)) {
        final img = _readyChunkImages.remove(k);
        img?.dispose();
        return true;
      }
      return false;
    });

    // 绘制已生成的图片
    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();
        final key = '${cx}_${cy}';

        final img = _readyChunkImages[key];
        if (img != null) {
          canvas.drawImage(
            img,
            Offset(chunkLeft - logicalOffset.x, chunkTop - logicalOffset.y),
            ui.Paint(),
          );
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 每帧限速生成最多2个chunk
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

        if (wx.abs() >= maxMapSize || wy.abs() >= maxMapSize) continue;

        _renderAdaptiveTile(
          canvas,
          wx,
          wy,
          tileSize,
          Offset(-originX, -originY),
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
      Offset offset,
      int depth,
      ) {
    if (depth > maxRecursionDepth) return;
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

  /// 🚀防抖+队列生成
  Future<void> ensureChunksForView({
    required Vector2 center,
    required Vector2 extra,
    bool forceImmediate = false,
  }) async {
    final roundedCenter = Vector2(center.x.roundToDouble(), center.y.roundToDouble());
    if (_lastEnsureCenter != null &&
        (_lastEnsureCenter! - roundedCenter).length < 1) {
      return;
    }
    _lastEnsureCenter = roundedCenter;

    final scale = viewScale;
    final visibleSize = viewSize / scale;

    final topLeft = roundedCenter - visibleSize / 2 - extra / 2;
    final bottomRight = roundedCenter + visibleSize / 2 + extra / 2;

    final startChunkX = (topLeft.x / chunkPixelSize).floor();
    final startChunkY = (topLeft.y / chunkPixelSize).floor();
    final endChunkX = (bottomRight.x / chunkPixelSize).ceil();
    final endChunkY = (bottomRight.y / chunkPixelSize).ceil();

    final awaitList = <Future<ui.Image>>[];

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final chunkLeft = cx * chunkPixelSize.toDouble();
        final chunkTop = cy * chunkPixelSize.toDouble();

        if (chunkLeft.abs() >= maxMapSize || chunkTop.abs() >= maxMapSize) continue;

        final key = '${cx}_${cy}';

        if (_readyChunkImages.containsKey(key)) {
          continue; // 已生成
        }

        if (!_chunkCache.containsKey(key)) {
          _chunkCache[key] = _ChunkCacheEntry();

          if (forceImmediate) {
            // 一次性生成
            awaitList.add(
              _generateChunkImage(cx, cy, key).then((img) {
                _readyChunkImages[key] = img;
                return img;
              }),
            );
          } else {
            // 分帧排队
            if (!_pendingChunks.any((e) => e.key == key)) {
              _pendingChunks.add(_PendingChunk(cx, cy, key));
            }
          }
        }
      }
    }

    if (awaitList.isNotEmpty) {
      await Future.wait(awaitList);
    }
  }
}

class _PendingChunk {
  final int cx;
  final int cy;
  final String key;
  _PendingChunk(this.cx, this.cy, this.key);
}
