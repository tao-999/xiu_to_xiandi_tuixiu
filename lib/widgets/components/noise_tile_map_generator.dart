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

  // ========= 性能缓存 =========
  // 每个 chunk 生成阶段：采样缓存（按 smallTileSize 量化到整点）
  final Map<int, _TerrainSample> _sampleCache = {};
  final Map<int, double> _hCache = {};
  final Map<int, double> _uCache = {};
  final Map<int, double> _tCache = {};
  final Map<int, double> _brightnessRowCache = {};
  // 预计算地形表
  static const List<(String type, ui.Color base)> _terrainDefs = [
    ('snow', ui.Color(0xFFEFEFEF)),
    ('grass', ui.Color(0xFF9BCB75)),
    ('rock', ui.Color(0xFF6D6A5F)),
    ('forest', ui.Color(0xFF3B5F4B)),
    ('flower_field', ui.Color(0xFFCCC19B)),
    ('shallow_ocean', ui.Color(0xFF4FA3C7)),
    ('beach', ui.Color(0xFFEAD7B6)),
    ('volcanic', ui.Color(0xFF7E3B3B)),
  ];
  // 预计算 HSL，减少每像素转换
  static final List<HSLColor> _terrainBaseHSL =
  _terrainDefs.map((e) => HSLColor.fromColor(Color(e.$2.value))).toList(growable: false);

  // 复用画笔
  final ui.Paint _chunkPaint = ui.Paint()
    ..isAntiAlias = false
    ..filterQuality = ui.FilterQuality.none;

  final ui.Paint _tilePaint = ui.Paint()..isAntiAlias = false;

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

        canvas.drawImageRect(img, src, dst, _chunkPaint);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _chunksGeneratedThisFrame = 0;
    // 优先生成靠近视野中心的（ensure 已排序）
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
    // 每个 chunk 开始：清空缓存（只对生成阶段有效）
    _sampleCache.clear();
    _hCache.clear();
    _uCache.clear();
    _tCache.clear();
    _brightnessRowCache.clear();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final extra = tileSize;
    final startX = -extra;
    final startY = -extra;
    final endX = chunkPixelSize + extra;
    final endY = chunkPixelSize + extra;

    final originX = cx * chunkPixelSize.toDouble();
    final originY = cy * chunkPixelSize.toDouble();

    // 步进常量化，避免在循环里反复做成员访问
    final step = tileSize;
    final localOffset = Offset(-originX, -originY);

    // 行级 brightness 预热：按 smallTileSize 量化的 y
    for (double y = startY; y < endY; y += smallTileSize) {
      final nyInt = (originY + y).floor();
      _brightnessRowCache[_packRowKey(nyInt)] = _getBrightnessOffsetForY(nyInt.toDouble());
    }

    for (double x = startX; x < endX; x += step) {
      for (double y = startY; y < endY; y += step) {
        _renderAdaptiveTile(
          canvas,
          originX + x,
          originY + y,
          step,
          localOffset,
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(chunkPixelSize, chunkPixelSize);
  }

  void _renderAdaptiveTile(ui.Canvas canvas, double wx, double wy, double size, Offset localOffset) {
    // 取四角+中心的地形索引（使用缓存，避免重复计算）
    final idx00 = _getTerrainIndex(wx, wy);
    final idx10 = _getTerrainIndex(wx + size, wy);
    final idx01 = _getTerrainIndex(wx, wy + size);
    final idx11 = _getTerrainIndex(wx + size, wy + size);
    final idxC  = _getTerrainIndex(wx + size / 2, wy + size / 2);

    // 判断是否同一种类型（避免 Set 分配）
    if (idx00 == idx10 && idx00 == idx01 && idx00 == idx11 && idx00 == idxC || size <= smallTileSize) {
      final color = _getTerrainColorForIndex(idxC, wy + size / 2);
      final dx = (wx + localOffset.dx).floorToDouble();
      final dy = (wy + localOffset.dy).floorToDouble();
      final pxSize = size.ceilToDouble();

      _tilePaint.color = color;
      canvas.drawRect(ui.Rect.fromLTWH(dx, dy, pxSize, pxSize), _tilePaint);
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
    final candidates = <_PendingChunk>[];

    for (int cx = startChunkX; cx <= endChunkX; cx++) {
      for (int cy = startChunkY; cy <= endChunkY; cy++) {
        final key = '${cx}_$cy';
        if (_readyChunks.containsKey(key) || _generatingChunks.contains(key)) continue;
        if (_pendingChunks.any((p) => p.key == key)) continue;

        candidates.add(_PendingChunk(cx, cy, key));
      }
    }

    // ✅ 距离中心排序，优先近处
    candidates.sort((a, b) {
      final acx = a.cx * chunkPixelSize + chunkPixelSize / 2;
      final acy = a.cy * chunkPixelSize + chunkPixelSize / 2;
      final bcx = b.cx * chunkPixelSize + chunkPixelSize / 2;
      final bcy = b.cy * chunkPixelSize + chunkPixelSize / 2;

      final da = (Vector2(acx.toDouble(), acy.toDouble()) - roundedCenter).length2;
      final db = (Vector2(bcx.toDouble(), bcy.toDouble()) - roundedCenter).length2;
      return da.compareTo(db);
    });

    if (forceImmediate) {
      for (final c in candidates) {
        if (_readyChunks.containsKey(c.key) || _generatingChunks.contains(c.key)) continue;
        _generatingChunks.add(c.key);
        futures.add(_generateChunkImage(c.cx, c.cy).then((img) {
          _readyChunks[c.key] = img;
          _generatingChunks.remove(c.key);
          return img;
        }));
      }
    } else {
      _pendingChunks.addAll(candidates);
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  // ============= 地形采样（缓存）=============
  int _getTerrainIndex(double nx, double ny) {
    // 以 smallTileSize 量化到网格整点，确保同一点命中缓存
    final ix = (nx / smallTileSize).floor();
    final iy = (ny / smallTileSize).floor();
    final key = _packKey(ix, iy);

    final cached = _sampleCache[key];
    if (cached != null) return cached.index;

    // 三通道噪声取样（也缓存）
    final hk = key; // 同一 key
    final uk = key ^ 0x9E3779B97F4A7C15; // 不同扰动，避免 Map 退化
    final tk = key ^ 0xC2B2AE3D27D4EB4F;

    final h1 = _hCache[hk] ??= (_noiseHeight.fbm(nx, ny, octaves, frequency, persistence) + 1) / 2;
    final h2 = _uCache[uk] ??= (_noiseHumidity.fbm(nx + 1e14, ny + 1e14, octaves, frequency, persistence) + 1) / 2;
    final h3 = _tCache[tk] ??= (_noiseTemperature.fbm(nx - 1e14, ny - 1e14, octaves, frequency, persistence) + 1) / 2;

    final mixed = (h1 * 0.4 + h2 * 0.3 + h3 * 0.3).clamp(0.0, 1.0);
    int idx;
    if (mixed < 0.4 || mixed > 0.6) {
      // 保持与原逻辑一致：极端都归为 shallow_ocean（索引=5）
      idx = 5;
    } else {
      final normalized = (mixed - 0.4) / 0.2;
      idx = (normalized * _terrainDefs.length).floor().clamp(0, _terrainDefs.length - 1);
    }

    _sampleCache[key] = _TerrainSample(index: idx);
    return idx;
  }

  ui.Color _getTerrainColorForIndex(int idx, double ny) {
    // 行级亮度缓存（ny 行）
    final nyInt = ny.floor();
    final rowKey = _packRowKey(nyInt);
    final brightnessOffset = _brightnessRowCache[rowKey] ??= _getBrightnessOffsetForY(nyInt.toDouble());

    final hsl = _terrainBaseHSL[idx];
    final adjusted = hsl.withLightness((hsl.lightness + brightnessOffset).clamp(0.0, 1.0));
    return adjusted.toColor();
  }

  // ========= 与旧 API 保持一致 =========
  String getTerrainTypeAtPosition(Vector2 worldPos) {
    final idx = _getTerrainIndex(worldPos.x, worldPos.y);
    return _terrainDefs[idx].$1;
  }

  // ========= 原亮度函数（未改语义）=========
  double _getBrightnessOffsetForY(double ny) {
    const segmentHeight = 200;
    const groupSize = 100;
    const offsetRange = 0.1;

    final blockIndex = ny ~/ segmentHeight;
    final localIndex = blockIndex % groupSize;

    final mirroredIndex = localIndex <= groupSize ~/ 2
        ? localIndex
        : groupSize - localIndex;

    final maxIndex = groupSize ~/ 2;
    final step = offsetRange / maxIndex;

    final offset = mirroredIndex * step;
    return offset;
  }

  // ========= Key 打包 =========
  static int _packKey(int ix, int iy) => (ix.toUnsigned(32) << 32) | (iy.toUnsigned(32));
  static int _packRowKey(int iy) => iy.toUnsigned(32);

}

class _PendingChunk {
  final int cx;
  final int cy;
  final String key;
  _PendingChunk(this.cx, this.cy, this.key);
}

class _TerrainSample {
  final int index;
  const _TerrainSample({required this.index});
}
