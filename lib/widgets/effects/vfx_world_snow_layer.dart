// 📂 lib/widgets/effects/vfx_world_snow_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/infinite_grid_painter_component.dart';
import '../components/noise_tile_map_generator.dart';

/// 用法：
/// final snow = WorldSnowLayer(
///   intensity: 0.5,
///   wind: Vector2(30, 80),
///   speedScale: 0.7,      // ↓整体下落速度
///   swayFreqScale: 0.6,   // ↓左右摆动频率
/// )..priority = 1150;
/// _grid!.add(snow);
class WorldSnowLayer extends Component with HasGameReference<FlameGame> {
  // —— 可调口味 ——（默认干净白雪，无发光/无模糊）
  final double tileSize;        // 生成/管理网格
  final double keepFactor;      // 生成/卸载范围（1.0=仅可视区）
  final double tilesFps;        // 扫描/生成/卸载频率（<=0 每帧）
  final double intensity;       // 0..1 雪量：密度/速度/大小/透明度
  final Vector2 wind;           // 世界风向（px/s）
  final int    updateSlices;    // 分帧更新（1=关闭）
  final bool   clipToView;      // 仅在可视区域内渲染
  final double speedScale;      // 整体下落速度倍率（1=原速）
  final double swayFreqScale;   // 左右摆动频率倍率（1=原频）

  // 图集（无发光、留 padding，杜绝“方块边”）
  final bool useAtlas;
  final int  cellSize;
  final int  atlasCols;
  final int  atlasRows;

  // —— 性能参数 ——
  final double fixedFps;        // 固定物理步长（0=关闭，默认60Hz）
  final bool   useSinLut;       // 用正弦查表优化

  // —— 内部 ——
  late InfiniteGridPainterComponent _grid;
  late NoiseTileMapGenerator _noise;
  final Map<String, _SnowPatch> _patches = {};

  double _t = 0;
  double _accTiles = 0;
  double _accum = 0;            // 固定步长累加器
  int _sliceCursor = 0;

  ui.Image? _atlas;
  late List<ui.Rect> _cells;
  static const double _ATLAS_INSET = 1.0;     // 采样内缩，避免取到邻格
  static const int _SNOW_SALT = 0x5A0B517;    // 合法的随机盐

  // 正弦LUT（长度需为 2^k）
  static const int _LUT_N = 1024;
  static final List<double> _sinLut =
  List<double>.generate(_LUT_N, (i) => sin(2 * pi * i / _LUT_N), growable: false);

  WorldSnowLayer({
    this.tileSize = 256.0,
    this.keepFactor = 1.0,
    this.tilesFps = 10.0,
    this.intensity = 0.6,
    Vector2? wind,
    this.updateSlices = 2,
    this.clipToView = true,
    this.useAtlas = true,
    this.cellSize = 32,
    this.atlasCols = 4,
    this.atlasRows = 2,
    this.fixedFps = 60.0,
    this.useSinLut = true,
    this.speedScale = 1.0,
    this.swayFreqScale = 1.0,
  }) : wind = wind ?? Vector2(50, 120);

  @override
  Future<void> onLoad() async {
    final g = parent as InfiniteGridPainterComponent?;
    if (g == null) return;
    _grid = g;
    _noise = g.generator;

    _atlas = await _makeSnowAtlas(cellSize, atlasCols, atlasRows);
    // 源 rect 内缩 1px，规避边缘取样
    _cells = List.generate(atlasCols * atlasRows, (i) {
      final cx = i % atlasCols;
      final cy = i ~/ atlasCols;
      final left = cx * cellSize + _ATLAS_INSET;
      final top  = cy * cellSize + _ATLAS_INSET;
      final w = cellSize - _ATLAS_INSET * 2;
      final h = cellSize - _ATLAS_INSET * 2;
      return ui.Rect.fromLTWH(left.toDouble(), top.toDouble(), w.toDouble(), h.toDouble());
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    // 本帧只算一次视口
    final cam  = _noise.logicalOffset;
    final view = game.size;
    final keep = _keepRect(cam, view);

    // —— 1) 生成/卸载（节流） ——
    var doTiles = true;
    if (tilesFps > 0) {
      _accTiles += dt;
      final step = 1.0 / tilesFps;
      if (_accTiles >= step) {
        _accTiles %= step;
      } else {
        doTiles = false;
      }
    }

    if (doTiles) {
      final sx = (keep.left / tileSize).floor();
      final sy = (keep.top  / tileSize).floor();
      final ex = (keep.right / tileSize).ceil();
      final ey = (keep.bottom/ tileSize).ceil();

      for (int tx = sx; tx < ex; tx++) {
        for (int ty = sy; ty < ey; ty++) {
          final key = '${tx}_${ty}';
          if (_patches.containsKey(key)) continue;

          final r = Random(_noise.seed ^ (tx * 92821) ^ (ty * 53987) ^ _SNOW_SALT);
          // 基准密度（以 128^2 为单位面积）
          final base  = 28;
          final areaK = (tileSize * tileSize) / (128.0 * 128.0);
          final count = max(6, (base * areaK * (0.35 + 1.2 * intensity)).round());

          final rect = _tileRect(tx, ty);
          final flakes = <_Flake>[];
          for (int i = 0; i < count; i++) {
            final depth  = _randRange(r, 0.55, 1.20); // 远近层
            final sizePx = _randRange(r, 6.0, 16.0) * depth * (0.7 + 0.9 * intensity);
            final fall   = _randRange(r, 60.0, 140.0) *
                depth * (0.7 + 1.1 * intensity) * speedScale;
            final alpha  = _randRange(r, 0.35, 0.85) * (0.65 + 0.6 * depth);
            final spinSp = _randRange(r, -1.2, 1.2);
            final swayA  = _randRange(r, 8.0, 26.0) * depth;
            final swayF  = _randRange(r, 0.4, 1.0) * swayFreqScale;
            final sprite = r.nextInt(atlasCols * atlasRows);

            final pos = Vector2(
              rect.left + r.nextDouble() * rect.width,
              rect.top  + r.nextDouble() * rect.height,
            );
            final vel = Vector2(0, fall) + wind * (0.6 + 0.6 * depth);

            flakes.add(_Flake(
              worldPos: pos,
              baseVel: vel,
              sizePx: sizePx,
              alpha: alpha,
              spin: r.nextDouble() * pi * 2,
              spinSpeed: spinSp,
              swayAmp: swayA,
              swayFreq: swayF,
              swayPhase: r.nextDouble() * pi * 2,
              depth: depth,
              spriteIndex: sprite,
              twinklePhase: r.nextDouble() * pi * 2,
            ));
          }

          _patches[key] = _SnowPatch(tx: tx, ty: ty, flakes: flakes);
        }
      }

      // 卸载
      final drop = <String>[];
      _patches.forEach((k, p) {
        final rect = _tileRect(p.tx, p.ty);
        if (!rect.overlaps(keep)) drop.add(k);
      });
      for (final k in drop) {
        _patches.remove(k);
      }
    }

    // —— 2) 固定步长 + 分片更新（无临时对象） ——
    final double h = (fixedFps <= 0) ? dt : (1.0 / fixedFps);
    double acc = (fixedFps <= 0) ? 0.0 : (_accum + dt);
    const int maxSub = 3; // 最多3子步，避免卡顿时超循环
    int substeps = 1;

    if (fixedFps > 0) {
      substeps = acc ~/ h;
      if (substeps > maxSub) substeps = maxSub;
      _accum = acc - substeps * h;
    }

    final int slices = updateSlices <= 1 ? 1 : updateSlices;
    for (int s = 0; s < substeps; s++) {
      final double stepDt = (fixedFps > 0) ? h : dt;
      final int sliceIdx = (slices <= 1) ? 0 : (_sliceCursor % slices);

      _patches.forEach((_, patch) {
        final fl = patch.flakes;
        for (int i = 0, n = fl.length; i < n; i++) {
          if (slices > 1 && (i % slices) != sliceIdx) continue;
          final f = fl[i];

          // 自旋
          f.spin += f.spinSpeed * stepDt;

          // 左右摆动：推进相位 + 快速正弦
          f.swayPhase += f.swayFreq * stepDt;
          final double swaySin = useSinLut ? _fastSin(f.swayPhase) : sin(f.swayPhase);
          final double sway = f.swayAmp * swaySin;

          // 位移（逐分量累加）
          f.worldPos.x += f.baseVel.x * stepDt + sway * stepDt;
          f.worldPos.y += f.baseVel.y * stepDt;

          // 回灌
          if (f.worldPos.y > keep.bottom + 24) {
            f.worldPos.y = keep.top - 12;
            f.worldPos.x += (f.baseVel.x * 0.02) + (_hashJitter(f, 13) - 0.5) * 28;
          }
        }
      });

      if (slices > 1) _sliceCursor = (_sliceCursor + 1) % slices;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (clipToView) {
      final v = game.size;
      canvas.save();
      canvas.clipRect(Rect.fromCenter(center: Offset.zero, width: v.x, height: v.y));
    }

    final cam = _noise.logicalOffset;

    if (useAtlas && _atlas != null) {
      final img = _atlas!;
      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.low; // 避免采样扩散到邻格

      final transforms = <ui.RSTransform>[];
      final rects = <ui.Rect>[];
      final colors = <Color>[];

      _patches.forEach((_, patch) {
        for (final f in patch.flakes) {
          final local = f.worldPos - cam;
          final angle = f.spin;

          // 轻微闪烁（只是 alpha 微变）
          final tw = 0.9 + 0.1 * sin(_t * 0.6 + f.twinklePhase);
          final a  = (f.alpha * tw).clamp(0.0, 1.0);

          final scale = (f.sizePx / cellSize).clamp(0.2, 2.5);

          transforms.add(ui.RSTransform.fromComponents(
            rotation: angle,
            scale: scale,
            anchorX: cellSize / 2,
            anchorY: cellSize / 2,
            translateX: local.x,
            translateY: local.y,
          ));
          rects.add(_cells[f.spriteIndex % _cells.length]);
          colors.add(Colors.white.withOpacity(a));
        }
      });

      if (transforms.isNotEmpty) {
        // 关键：modulate 只调制非透明像素，不会把整格染成方块
        canvas.drawAtlas(img, transforms, rects, colors, BlendMode.modulate, null, paint);
      }
    } else {
      // 兜底：不用图集，直接画纯白软圆
      final p = Paint()..style = PaintingStyle.fill;
      _patches.forEach((_, patch) {
        for (final f in patch.flakes) {
          final local = f.worldPos - cam;
          p.color = Colors.white.withOpacity(f.alpha);
          canvas.drawCircle(Offset(local.x, local.y), f.sizePx * 0.5, p);
        }
      });
    }

    if (clipToView) canvas.restore();
  }

  // —— 工具 —— //
  Rect _keepRect(Vector2 center, Vector2 view) {
    final keep = view * keepFactor;
    final tl = center - keep / 2;
    return Rect.fromLTWH(tl.x, tl.y, keep.x, keep.y);
  }

  Rect _tileRect(int tx, int ty) =>
      Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);

  static double _randRange(Random r, double a, double b) =>
      a + r.nextDouble() * (b - a);

  // 干净图集：无发光/无模糊，留 30% padding，图形不碰 cell 边
  Future<ui.Image> _makeSnowAtlas(int s, int cols, int rows) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    final W = (s * cols).toDouble();
    final H = (s * rows).toDouble();
    c.clipRect(Rect.fromLTWH(0, 0, W, H));

    final pad = s * 0.30;                 // 30% 透明边距
    final inside = 1.0 - (pad * 2) / s;

    Paint pFill(double a) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(a);

    Paint pStroke(double a, double w) => Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(a);

    for (int r = 0; r < rows; r++) {
      for (int q = 0; q < cols; q++) {
        final x = q * s, y = r * s;
        final cx = x + s / 2.0, cy = y + s / 2.0;
        final center = Offset(cx.toDouble(), cy.toDouble());
        final idx = r * cols + q;

        switch (idx % 4) {
          case 0: // 软圆
            c.drawCircle(center, s * 0.42 * inside, pFill(0.95));
            break;
          case 1: // 简易六角
            final len = s * 0.30 * inside;
            final core = pStroke(0.95, 1.2);
            for (int i = 0; i < 6; i++) {
              final a = i * pi / 3;
              final o = Offset(center.dx + cos(a) * len, center.dy + sin(a) * len);
              c.drawLine(center, o, core);
            }
            break;
          case 2: // 三团簇
            c.drawCircle(Offset(cx - s * 0.10 * inside, cy),            s * 0.14 * inside, pFill(0.95));
            c.drawCircle(Offset(cx + s * 0.07 * inside, cy - s * 0.06), s * 0.12 * inside, pFill(0.95));
            c.drawCircle(Offset(cx + s * 0.02 * inside, cy + s * 0.08), s * 0.10 * inside, pFill(0.95));
            break;
          default: // 小点
            c.drawCircle(center, s * 0.10 * inside, pFill(0.95));
        }
      }
    }

    final pic = rec.endRecording();
    return pic.toImage(s * cols, s * rows);
  }

  @pragma('vm:prefer-inline')
  double _fastSin(double phase) {
    final double idx = phase * (_LUT_N / (2 * pi));
    final int i = idx.floor() & (_LUT_N - 1);
    final int j = (i + 1) & (_LUT_N - 1);
    final double t = idx - idx.floorToDouble();
    return _sinLut[i] + (_sinLut[j] - _sinLut[i]) * t;
  }

  double _hashJitter(_Flake f, int salt) {
    final h = f.worldPos.x.toInt() * 73856093 ^ f.worldPos.y.toInt() * 19349663 ^ salt;
    return ((h & 0xFFFF) / 65535.0);
  }
}

// ===== 内部结构 =====
class _SnowPatch {
  final int tx, ty;
  final List<_Flake> flakes;
  _SnowPatch({required this.tx, required this.ty, required this.flakes});
}

class _Flake {
  Vector2 worldPos;
  final Vector2 baseVel;
  final double sizePx;
  final double alpha;
  double spin;
  final double spinSpeed;
  final double swayAmp;
  double swayFreq;
  double swayPhase;
  final double depth;
  final int spriteIndex;
  final double twinklePhase;

  _Flake({
    required this.worldPos,
    required this.baseVel,
    required this.sizePx,
    required this.alpha,
    required this.spin,
    required this.spinSpeed,
    required this.swayAmp,
    required this.swayFreq,
    required this.swayPhase,
    required this.depth,
    required this.spriteIndex,
    required this.twinklePhase,
  });
}
