// 📂 lib/widgets/effects/vfx_world_mist_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/noise_tile_map_generator.dart';

enum MistMixMode { solid, linear, hsv }

class WorldMistLayer extends Component {
  // ===== 外部环境 =====
  final Component grid; // 建议挂在 _grid
  final Vector2 Function() getLogicalOffset; // 相机中心（世界系）
  final Vector2 Function() getViewSize;      // 画布像素尺寸
  final String Function(Vector2) getTerrainType;
  final NoiseTileMapGenerator? noiseMapGenerator;

  // ===== Tile 配置 =====
  final double tileSize;
  final int seed;

  // ===== 出现概率/密度 =====
  final double spawnProbability; // 每 tile 生成雾片概率（0~1）
  double density;                // 影响 puff 数量/透明度/速度

  // ===== Puff 行为参数 =====
  final int minPuffsPerTile;
  final int maxPuffsPerTile;
  final double puffRadiusMin;
  final double puffRadiusMax;
  final double alphaMin;
  final double alphaMax;
  final double alphaFloor;       // 吹散后不低于此不透明度（不消失）
  final double speedMin;
  final double speedMax;
  final Vector2 globalWind;      // 世界风（px/s）
  final double pulseSpeedMin;    // 呼吸速度
  final double pulseSpeedMax;
  final double pulseAmpMin;      // 呼吸幅度（半径倍率）
  final double pulseAmpMax;

  // ===== 阵风（吹散）效果 =====
  final double gustStrength; // 吹散强度（0~1）
  final double gustSpeed;    // 吹散速度（影响噪声/时间变化）

  // ===== 渲染 =====
  final MistMixMode mixMode;
  final bool useGradient;
  final Set<String> allowedTerrains;
  final List<Color> Function(String terrain)? paletteResolver;

  // ===== 可选提速（默认全关，不影响原味） =====
  final double tilesFps;          // >0 对“生成/卸载”节流；<=0 每帧扫描
  final bool budgetEnabled;       // 屏幕雾量预算（超预算本轮不生成）
  final int puffsPer100kpx;       // 预算：每10万像素目标雾团数
  final int hardPuffCap;          // 绝对上限（保险丝）
  final int updateSlices;         // 分帧更新切片（1=不分帧）

  // ===== 批渲染（可选）——有机云贴图 + drawAtlas =====
  final bool useAtlas;            // 开启批渲染
  final int atlasSize;            // 贴图尺寸（64/128）
  final int atlasVariants;        // 变体数量（3~5）
  final bool atlasOrganic;        // true: 有机云；false: 软圆（不建议）

  // ===== 内部状态 =====
  final Map<String, _MistPatch> _patches = {}; // key: "tx_ty"
  double _time = 0;

  // 频率累计器 / 分帧游标
  double _accTiles = 0;
  int _sliceCursor = 0;

  // atlas 资源
  List<ui.Image>? _blobImgs;

  WorldMistLayer({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    required this.allowedTerrains,
    this.noiseMapGenerator,
    this.tileSize = 128.0,
    this.seed = 9527,
    this.spawnProbability = 0.6,
    this.density = 0.6,
    this.minPuffsPerTile = 6,
    this.maxPuffsPerTile = 12,
    this.puffRadiusMin = 18,
    this.puffRadiusMax = 48,
    this.alphaMin = 0.08,
    this.alphaMax = 0.20,
    this.alphaFloor = 0.025,
    this.speedMin = 6.0,
    this.speedMax = 22.0,
    Vector2? globalWind,
    this.pulseSpeedMin = 0.3,
    this.pulseSpeedMax = 0.9,
    this.pulseAmpMin = 0.06,
    this.pulseAmpMax = 0.18,
    this.gustStrength = 0.6,
    this.gustSpeed = 0.35,
    this.mixMode = MistMixMode.hsv,
    this.useGradient = true,
    this.paletteResolver,

    // 可选提速（默认全关）
    this.tilesFps = 0.0,
    this.budgetEnabled = false,
    this.puffsPer100kpx = 35,
    this.hardPuffCap = 2000,
    this.updateSlices = 1,

    // 批渲染（默认关）
    this.useAtlas = false,
    this.atlasSize = 64,
    this.atlasVariants = 3,
    this.atlasOrganic = true,
  }) : globalWind = globalWind ?? Vector2(8, -2);

  // ===== 资源加载（atlas 可选）=====
  @override
  Future<void> onLoad() async {
    if (useAtlas) {
      _blobImgs = [];
      final rng = Random(seed ^ 0x5f3759df);
      for (int i = 0; i < atlasVariants; i++) {
        if (atlasOrganic) {
          _blobImgs!.add(await _makeSoftBlob(atlasSize, rng.nextInt(1 << 31)));
        } else {
          _blobImgs!.add(await _makeSoftCircle(atlasSize));
        }
      }
    }
  }

  // ===== 工具：地形获取（与动态口径一致）=====
  String _classify(Vector2 p) {
    if (noiseMapGenerator != null) {
      return noiseMapGenerator!.getTerrainTypeAtPosition(p);
    }
    return getTerrainType(p);
  }

  // 出现概率（可按地形微调）
  double _spawnProbFor(String terrain) {
    return (spawnProbability * (0.5 + 0.8 * density)).clamp(0.0, 1.0);
  }

  // 可视区域 ×1.25 的保留矩形（世界系）
  Rect _keepRect(Vector2 center, Vector2 view) {
    final keep = view * 1.25;
    final topLeft = center - keep / 2;
    return Rect.fromLTWH(topLeft.x, topLeft.y, keep.x, keep.y);
  }

  // tile → 矩形（世界系）
  Rect _tileRect(int tx, int ty) {
    return Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);
  }

  // 预算用：当前 keep 内雾团数量
  int _countVisiblePuffs(Rect keep) {
    int n = 0;
    _patches.forEach((_, patch) {
      final rect = Rect.fromLTWH(patch.tx * tileSize, patch.ty * tileSize, tileSize, tileSize);
      if (rect.overlaps(keep)) n += patch.puffs.length;
    });
    return n;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final cam = getLogicalOffset();
    final view = getViewSize();
    final keep = _keepRect(cam, view);

    // —— 1) 生成/卸载（可节流）——
    bool doTilesStep = true;
    if (tilesFps > 0) {
      _accTiles += dt;
      final step = 1.0 / tilesFps;
      if (_accTiles >= step) {
        _accTiles %= step;
        doTilesStep = true;
      } else {
        doTilesStep = false;
      }
    }

    if (doTilesStep) {
      final startX = (keep.left / tileSize).floor();
      final startY = (keep.top / tileSize).floor();
      final endX   = (keep.right / tileSize).ceil();
      final endY   = (keep.bottom / tileSize).ceil();

      int curPuffs = 0, budget = 1 << 30;
      if (budgetEnabled) {
        curPuffs = _countVisiblePuffs(keep);
        budget = (keep.width * keep.height / 100000.0 * puffsPer100kpx).round();
      }

      for (int tx = startX; tx < endX; tx++) {
        for (int ty = startY; ty < endY; ty++) {
          final rect = _tileRect(tx, ty);
          if (!rect.overlaps(keep)) continue;

          final center = Vector2(rect.center.dx, rect.center.dy);
          final terrain = _classify(center);
          if (!allowedTerrains.contains(terrain)) continue;

          final key = '${tx}_${ty}';
          if (_patches.containsKey(key)) continue;

          if (budgetEnabled && (curPuffs >= hardPuffCap || curPuffs >= budget)) {
            continue; // 等回收
          }

          final r = Random(seed + tx * 92821 + ty * 53987 + 777);
          final appear = r.nextDouble() < _spawnProbFor(terrain);
          if (!appear) continue;

          final palette = (paletteResolver ?? _defaultPaletteForTerrain)(terrain);

          // puff 数量受 density 影响（原配方）
          final baseCount = _randRangeInt(r, minPuffsPerTile, maxPuffsPerTile);
          final puffCount = (baseCount * (0.5 + 0.8 * density)).round().clamp(1, 999);

          final puffs = <_Puff>[];
          for (int i = 0; i < puffCount; i++) {
            final a = palette[r.nextInt(palette.length)];
            Color b = palette[r.nextInt(palette.length)];
            if (palette.length > 1) {
              int guard = 0;
              while (b == a && guard++ < 4) {
                b = palette[r.nextInt(palette.length)];
              }
            }

            final worldPos = Vector2(
              rect.left + r.nextDouble() * tileSize,
              rect.top  + r.nextDouble() * tileSize,
            );

            final ang = r.nextDouble() * pi * 2;
            final spd = _randRange(r, speedMin, speedMax);
            final vel = Vector2(cos(ang), sin(ang)) * spd;

            final rad = _randRange(r, puffRadiusMin, puffRadiusMax);
            final alp = _randRange(r, alphaMin, alphaMax);

            final pulseSpd = _randRange(r, pulseSpeedMin, pulseSpeedMax);
            final pulseAmp = _randRange(r, pulseAmpMin, pulseAmpMax);

            // atlas 变体与旋转（即使没开 atlas 也无伤大雅）
            final varIdx = (_blobImgs == null || _blobImgs!.isEmpty)
                ? 0
                : r.nextInt(_blobImgs!.length);
            final rot = r.nextDouble() * pi * 2;

            puffs.add(_Puff(
              worldPos: worldPos,
              vel: vel,
              baseRadius: rad,
              baseAlpha: alp,
              cA: a, cB: b,
              pulseSpeed: pulseSpd,
              pulseAmp: pulseAmp,
              phase: r.nextDouble() * pi * 2,
              gustPhase: r.nextDouble() * pi * 2,
              atlasVar: varIdx,
              rot: rot,
              useGradient: useGradient,
              mixMode: mixMode,
            ));
          }

          _patches[key] = _MistPatch(tx: tx, ty: ty, puffs: puffs);
          if (budgetEnabled) curPuffs += puffs.length;
        }
      }

      // 回收超出 keep 的 tiles
      final toRemove = <String>[];
      _patches.forEach((key, patch) {
        final rect = _tileRect(patch.tx, patch.ty);
        if (!rect.overlaps(keep)) toRemove.add(key);
      });
      for (final k in toRemove) {
        _patches.remove(k);
      }
    }

    // —— 2) 逐帧更新（世界系运动 + 吹散）—— 仍保持原配方
    final wind = globalWind; // 不 clone，避免分配
    final gustK = gustStrength.clamp(0.0, 1.0);
    final slices = updateSlices <= 1 ? 1 : updateSlices;
    final sliceIdx = _sliceCursor;

    _patches.forEach((_, patch) {
      int idx = 0;
      for (final p in patch.puffs) {
        if (slices > 1 && (idx++ % slices) != sliceIdx) continue;

        // ① 位移：基础速度 + 全局风
        p.worldPos += (p.vel + wind) * dt;

        // ② 呼吸
        p.phase += p.pulseSpeed * dt;

        // ③ 阵风（吹散）：半径↑、透明度↓、速度略抖动
        final gust = 0.5 + 0.5 * sin(_time * gustSpeed + p.gustPhase); // 0~1
        final disperse = gust * gustK;

        // 半径扩张（最多 +90%）
        p.curRadius = p.baseRadius * (1.0 + 0.9 * disperse);

        // 透明度降低，但保底 alphaFloor
        p.curAlpha = (p.baseAlpha * (1.0 - 0.75 * disperse)).clamp(alphaFloor, 1.0);

        // 速度抖动（小幅随机“撕裂”感）
        final jitterAng = (_time * 0.7 + p.gustPhase) % (pi * 2);
        final jitter = Vector2(cos(jitterAng), sin(jitterAng)) * (2.0 + 6.0 * disperse);
        p.worldPos += jitter * dt;
      }
    });
    if (slices > 1) {
      _sliceCursor = (_sliceCursor + 1) % slices;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cam = getLogicalOffset();

    // —— 批渲染（可选）——
    if (useAtlas && _blobImgs != null && _blobImgs!.isNotEmpty) {
      final paint = Paint()..filterQuality = FilterQuality.high;

      for (int v = 0; v < _blobImgs!.length; v++) {
        final transforms = <ui.RSTransform>[];
        final rects = <ui.Rect>[];
        final colors = <Color>[];

        final img = _blobImgs![v];
        final src = ui.Rect.fromLTWH(
          1, 1, (img.width - 2).toDouble(), (img.height - 2).toDouble(), // 内缩1px防止出血
        );

        for (final patch in _patches.values) {
          for (final p in patch.puffs) {
            if (p.atlasVar != v) continue;

            final local = p.worldPos - cam;
            final r = (p.curRadius ?? p.baseRadius).toDouble();
            final a = (p.curAlpha ?? p.baseAlpha).toDouble();

            transforms.add(ui.RSTransform.fromComponents(
              rotation: p.rot,
              scale: (r * 2) / src.width, // 直径缩放
              anchorX: src.width / 2, anchorY: src.height / 2,
              translateX: local.x, translateY: local.y,
            ));
            rects.add(src);

            // 用中间色调 Tint，透明度来自 puff
            colors.add(p._mix(0.35).withOpacity(a));
          }
        }

        if (transforms.isNotEmpty) {
          canvas.drawAtlas(
            img, transforms, rects, colors,
            BlendMode.modulate, // 关键：乘法调色，透明区不盖方块
            null, paint,
          );
        }
      }
      return; // atlas 分支已经画完
    }

    // —— 原始渲染路径（逐个 gradient/solid）——
    for (final patch in _patches.values) {
      for (final p in patch.puffs) {
        final local = p.worldPos - cam;
        final r = p.curRadius ?? p.baseRadius;
        final a = p.curAlpha ?? p.baseAlpha;

        if (useGradient) {
          final shader = ui.Gradient.radial(
            Offset(local.x, local.y), r.toDouble(),
            [p._mix(0.0).withOpacity(a), p._mix(1.0).withOpacity(0.0)],
            const [0.0, 1.0],
          );
          final paint = Paint()
            ..shader = shader
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(Offset(local.x, local.y), r.toDouble(), paint);
        } else {
          final color = p._mix(0.35).withOpacity(a);
          final paint = Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(local.x, local.y), r.toDouble(), paint);
        }
      }
    }
  }

  // ===== Palette 默认表 =====
  List<Color> _defaultPaletteForTerrain(String terrain) {
    switch (terrain) {
      case 'forest':
      case 'grass':
      case 'plain':
        return const [Color(0x99C8FACC), Color(0x66A8E6A8), Color(0x6690FFC0)];
      case 'swamp':
        return const [Color(0x6690A955), Color(0x665B7F2A), Color(0x6680A958)];
      case 'desert':
      case 'sand':
        return const [Color(0x66FFE6A8), Color(0x66FFD27F), Color(0x66FFC76E)];
      case 'snow':
      case 'ice':
        return const [Color(0x66E8F7FF), Color(0x66CCF2FF), Color(0x66DFF7FF)];
      case 'lava':
      case 'volcano':
        return const [Color(0x66FF6B6B), Color(0x66FF964F), Color(0x66FFAA33)];
      case 'water':
      case 'lake':
      case 'river':
        return const [Color(0x66B3E5FF), Color(0x667FD1FF), Color(0x6690E0FF)];
      case 'mountain':
      case 'rock':
        return const [Color(0x66B0B8C2), Color(0x6698A0AA), Color(0x669AA5AF)];
      default:
        return const [Color(0x66EFE7FF), Color(0x66C9B9FF), Color(0x66D9CCFF)];
    }
  }

  // ===== 小工具 =====
  static double _randRange(Random r, double a, double b) => a + r.nextDouble() * (b - a);
  static int _randRangeInt(Random r, int a, int b) => a + r.nextInt((b - a + 1).clamp(1, 1 << 30));

  // —— 软圆（不建议，容易看出圆形；保留以备切换）——
  Future<ui.Image> _makeSoftCircle(int size) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final center = Offset(size / 2, size / 2);
    final r = size / 2 - 1; // 留1px透明边，缩放更干净
    final shader = ui.Gradient.radial(
      center, r,
      const [Colors.white, Colors.transparent],
      const [0.0, 1.0],
    );
    final p = Paint()..shader = shader;
    c.drawCircle(center, r, p);
    final pic = rec.endRecording();
    return await pic.toImage(size, size);
  }

  // —— 有机云（metaball 多瓣）——
  Future<ui.Image> _makeSoftBlob(int size, int seed) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rng = Random(seed);

    final center = Offset(size / 2, size / 2);
    final baseR  = size / 2 - 1; // 预留1px透明边

    // 外层淡雾打底
    final outer = Paint()
      ..shader = ui.Gradient.radial(
        center, baseR,
        [Colors.white.withOpacity(0.22), Colors.transparent],
        const [0.0, 1.0],
      );
    c.drawCircle(center, baseR, outer);

    // 多瓣云瓣
    final lobes = 4 + rng.nextInt(3); // 4..6瓣
    for (int i = 0; i < lobes; i++) {
      final ang  = rng.nextDouble() * pi * 2;
      final dist = baseR * (0.15 + rng.nextDouble() * 0.35);
      final rr   = baseR * (0.30 + rng.nextDouble() * 0.45);
      final op   = 0.35 + rng.nextDouble() * 0.50;

      final cx = center.dx + cos(ang) * dist;
      final cy = center.dy + sin(ang) * dist;

      final p = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy), rr,
          [Colors.white.withOpacity(op), Colors.transparent],
          const [0.0, 1.0],
        );
      c.drawCircle(Offset(cx, cy), rr, p);
    }

    // 微弱内核（去死白点）
    final coreR = baseR * 0.22;
    final core = Paint()
      ..shader = ui.Gradient.radial(
        center, coreR,
        [Colors.white.withOpacity(0.32), Colors.transparent],
        const [0.0, 1.0],
      );
    c.drawCircle(center, coreR, core);

    final pic = rec.endRecording();
    return await pic.toImage(size, size);
  }
}

// ===== 内部结构 =====
class _MistPatch {
  final int tx, ty;
  final List<_Puff> puffs;
  _MistPatch({required this.tx, required this.ty, required this.puffs});
}

class _Puff {
  Vector2 worldPos;   // 世界系坐标（跨 tile 漂）
  Vector2 vel;        // 自身基础速度（叠加 globalWind）
  double baseRadius;  // 基础半径
  double baseAlpha;   // 基础透明度
  double? curRadius;  // 动态半径（受吹散/呼吸影响）
  double? curAlpha;   // 动态不透明度
  final Color cA, cB;
  double pulseSpeed;
  double pulseAmp;
  double phase;
  double gustPhase;   // 吹散相位

  // atlas 变体 & 旋转（可选）
  int atlasVar;
  double rot;

  final bool useGradient;
  final MistMixMode mixMode;

  _Puff({
    required this.worldPos,
    required this.vel,
    required this.baseRadius,
    required this.baseAlpha,
    required this.cA,
    required this.cB,
    required this.pulseSpeed,
    required this.pulseAmp,
    required this.phase,
    required this.gustPhase,
    this.atlasVar = 0,
    this.rot = 0.0,
    required this.useGradient,
    required this.mixMode,
  });

  // ⚡ 快速返回，避免没必要的 HSV/ARGB 计算
  Color _mix(double t) {
    if (t <= 0.0) return cA;
    if (t >= 1.0) return cB;
    switch (mixMode) {
      case MistMixMode.solid:
        return cA;
      case MistMixMode.linear:
        return Color.fromARGB(
          (cA.alpha + (cB.alpha - cA.alpha) * t).round(),
          (cA.red   + (cB.red   - cA.red)   * t).round(),
          (cA.green + (cB.green - cA.green) * t).round(),
          (cA.blue  + (cB.blue  - cA.blue)  * t).round(),
        );
      case MistMixMode.hsv:
        final ah = HSVColor.fromColor(cA);
        final bh = HSVColor.fromColor(cB);
        final dh = ((bh.hue - ah.hue + 540) % 360) - 180;
        final hue = (ah.hue + dh * t + 360) % 360;
        final sat = ah.saturation + (bh.saturation - ah.saturation) * t;
        final val = ah.value + (bh.value - ah.value) * t;
        final alp = cA.opacity + (cB.opacity - cA.opacity) * t;
        return HSVColor.fromAHSV(alp, hue, sat, val).toColor();
    }
  }
}
