// 📂 lib/widgets/effects/vfx_world_mist_layer.dart
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/noise_tile_map_generator.dart';

enum MistMixMode { solid, linear, hsv }

class WorldMistLayer extends Component {
  // ===== 外部环境 =====
  final Component grid;
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
  final double alphaFloor;       // 吹散后不低于此不透明度
  final double speedMin;
  final double speedMax;
  final Vector2 globalWind;      // 世界风（px/s）
  final double pulseSpeedMin;    // 呼吸速度
  final double pulseSpeedMax;
  final double pulseAmpMin;      // 呼吸幅度（半径倍率）
  final double pulseAmpMax;

  // ===== 阵风（吹散）效果 =====
  final double gustStrength; // 吹散强度（0~1）
  final double gustSpeed;    // 吹散速度（影响时间项）

  // ===== 渲染 =====
  final MistMixMode mixMode;
  final bool useGradient;
  final Set<String> allowedTerrains;
  final List<Color> Function(String terrain)? paletteResolver;

  // ===== 可选提速 =====
  final double tilesFps;          // >0 生成/卸载节流；<=0 每帧
  final bool budgetEnabled;       // 屏幕雾量预算
  final int puffsPer100kpx;       // 预算：每10万像素目标雾团
  final int hardPuffCap;          // 绝对上限
  final int updateSlices;         // puff 级分片（1=不分片）
  final int tilesSlices;          // tile 级分片（1=不分片）

  // —— 生成/回收/更新 矩形 —— //
  final double spawnRectScale;    // 生成半径（视口倍数）
  final double cleanupRectScale;  // 回收半径（视口倍数）
  final double updateRectScale;   // 每帧更新半径（视口倍数）
  final int updatePatchSlices;    // patch 级分片：不在 updateRect 的 patch 轮询刷
  final double patchGraceSeconds; // 离开清理区后的宽限期
  final double renderBudgetScale; // 预算矩形（视口倍数）

  // ===== 批渲染（强推） =====
  final bool useAtlas;
  final int atlasSize;
  final int atlasVariants;
  final bool atlasOrganic;

  // ===== LRU 模板缓存（可选） =====
  final bool cacheEnabled;
  final int cacheCap;

  // ===== 美术开关：丝状雾（wispy） =====
  final bool wispyMode;           // 开“缕状雾”
  final int strandLenMin;         // 每条最少段数
  final int strandLenMax;         // 每条最多段数
  final double strandStepMin;     // 段间距（像素）
  final double strandStepMax;
  final double strandJitter;      // 每段抖动幅度（像素）
  final double wispyAnisoMin;     // 贴图纵横比（>1 更细长）
  final double wispyAnisoMax;

  // ===== 内部状态 =====
  final Map<String, _MistPatch> _patches = {}; // 活跃 patch：key= "tx_ty"
  final Map<String, _PuffTemplateList> _cache = {};
  final Queue<String> _cacheOrder = Queue<String>();

  // atlas 资源与复用容器
  List<ui.Image>? _blobImgs;
  final List<List<ui.RSTransform>> _atlTransforms = [];
  final List<List<ui.Rect>> _atlRects = [];
  final List<List<Color>> _atlColors = [];
  final List<ui.Rect> _srcRects = []; // 每个变体一个 srcRect 复用

  double _time = 0;
  double _accTiles = 0;
  int _sliceCursor = 0; // puff 更新片游标
  int _tilesCursor = 0; // tile 扫描片游标
  int _patchCursor = 0; // patch 级分片游标
  int _visiblePuffs = 0; // 预算用增量计数（近似）

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

    // 可选提速
    this.tilesFps = 0.0,
    this.budgetEnabled = false,
    this.puffsPer100kpx = 35,
    this.hardPuffCap = 2000,
    this.updateSlices = 1,
    this.tilesSlices = 1,

    // 矩形/分片/宽限
    this.spawnRectScale = 1.35,
    this.cleanupRectScale = 1.20,
    this.updateRectScale = 1.10,
    this.updatePatchSlices = 4,
    this.patchGraceSeconds = 0.35,
    this.renderBudgetScale = 1.05,

    // 批渲染
    this.useAtlas = true,
    this.atlasSize = 64,
    this.atlasVariants = 3,
    this.atlasOrganic = true,

    // LRU 模板缓存
    this.cacheEnabled = true,
    this.cacheCap = 256,

    // 丝状雾
    this.wispyMode = true,
    this.strandLenMin = 3,
    this.strandLenMax = 6,
    this.strandStepMin = 26,
    this.strandStepMax = 48,
    this.strandJitter = 10,
    this.wispyAnisoMin = 1.6,
    this.wispyAnisoMax = 3.2,
  }) : globalWind = globalWind ?? Vector2(10, -3);

  // ===== 资源加载 =====
  @override
  Future<void> onLoad() async {
    if (useAtlas) {
      _blobImgs = [];
      final rng = Random(seed ^ 0x5f3759df);
      for (int i = 0; i < atlasVariants; i++) {
        final img = wispyMode
            ? await _makeWispyBlob(
          atlasSize,
          rng.nextInt(1 << 31),
          aniso: _randRange(rng, wispyAnisoMin, wispyAnisoMax),
        )
            : (atlasOrganic
            ? await _makeSoftBlob(atlasSize, rng.nextInt(1 << 31))
            : await _makeSoftCircle(atlasSize));
        _blobImgs!.add(img);
        _srcRects.add(ui.Rect.fromLTWH(
            2, 2, (img.width - 4).toDouble(), (img.height - 4).toDouble())); // ✅ from 1→2
        _atlTransforms.add(<ui.RSTransform>[]);
        _atlRects.add(<ui.Rect>[]);
        _atlColors.add(<Color>[]);
      }
    }
  }

  // ===== 工具：地形获取 =====
  String _classify(Vector2 p) =>
      noiseMapGenerator != null ? noiseMapGenerator!.getTerrainTypeAtPosition(p) : getTerrainType(p);

  // 出现概率（可按地形微调）
  double _spawnProbFor(String _terrain) =>
      (spawnProbability * (0.5 + 0.8 * density)).clamp(0.0, 1.0);

  // 矩形（世界系）
  Rect _rectScaled(Vector2 center, Vector2 view, double scale) {
    final keep = view * scale;
    final topLeft = center - keep / 2;
    return Rect.fromLTWH(topLeft.x, topLeft.y, keep.x, keep.y);
  }

  // tile → 矩形（世界系）
  Rect _tileRect(int tx, int ty) =>
      Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);

  // ===== 主循环 =====
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final cam = getLogicalOffset();
    final view = getViewSize();

    final spawnRect   = _rectScaled(cam, view, spawnRectScale);
    final cleanupRect = _rectScaled(cam, view, cleanupRectScale);
    final updateRect  = _rectScaled(cam, view, updateRectScale);
    final budgetRect  = _rectScaled(cam, view, renderBudgetScale);

    // —— 1) 生成/卸载（可节流 + 分片）——
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
      final startX = (spawnRect.left / tileSize).floor();
      final startY = (spawnRect.top / tileSize).floor();
      final endX   = (spawnRect.right / tileSize).ceil();
      final endY   = (spawnRect.bottom / tileSize).ceil();

      int curPuffs = _visiblePuffs;
      int budget = 1 << 30;
      if (budgetEnabled) {
        budget = (budgetRect.width * budgetRect.height / 100000.0 * puffsPer100kpx).round();
      }

      for (int tx = startX; tx < endX; tx++) {
        for (int ty = startY; ty < endY; ty++) {
          if (tilesSlices > 1 && ((tx + ty - _tilesCursor) % tilesSlices) != 0) continue;

          final rect = _tileRect(tx, ty);
          if (!rect.overlaps(spawnRect)) continue;

          final key = '${tx}_${ty}';
          if (_patches.containsKey(key)) {
            _patches[key]!._lastInsideTime = _time;
            continue;
          }

          if (budgetEnabled && (curPuffs >= hardPuffCap || curPuffs >= budget)) continue;

          final center = Vector2(rect.center.dx, rect.center.dy);
          final terrain = _classify(center);
          if (!allowedTerrains.contains(terrain)) continue;

          final r = Random(seed + tx * 92821 + ty * 53987 + 777);
          if (r.nextDouble() >= _spawnProbFor(terrain)) continue;

          final patch = _spawnPatch(tx, ty, terrain, rect, r);
          _patches[key] = patch;
          _visiblePuffs += patch.puffs.length;
          curPuffs += patch.puffs.length;
          patch._lastInsideTime = _time;
        }
      }

      // 回收（离开清理区 + 宽限期）
      final toRemove = <String>[];
      _patches.forEach((key, patch) {
        final rect = _tileRect(patch.tx, patch.ty);
        if (rect.overlaps(cleanupRect)) {
          patch._lastInsideTime = _time;
          return;
        }
        if ((_time - patch._lastInsideTime) >= patchGraceSeconds) {
          toRemove.add(key);
        }
      });
      for (final k in toRemove) {
        final p = _patches.remove(k);
        if (p == null) continue;
        _visiblePuffs -= p.puffs.length;
        if (cacheEnabled) _pushCache(k, _PuffTemplateList.fromPatch(p, tileSize));
      }

      if (tilesSlices > 1) _tilesCursor = (_tilesCursor + 1) % tilesSlices;
    }

    // —— 2) 逐帧更新（只更新 updateRect 内的 patch；外侧按分片轮询）——
    _updatePuffs(dt, updateRect);
  }

  void _updatePuffs(double dt, Rect updateRect) {
    // 两次/帧预计算三角函数
    final tg = _time * gustSpeed;
    final sinTg = sin(tg), cosTg = cos(tg);
    final tj = _time * 0.7;
    final sinTj = sin(tj), cosTj = cos(tj);

    final gustK = gustStrength.clamp(0.0, 1.0);
    final wind = globalWind;
    final puffSlices = updateSlices <= 1 ? 1 : updateSlices;
    final puffSliceIdx = _sliceCursor;

    int patchIdx = 0;
    _patches.forEach((_, patch) {
      final rect = _tileRect(patch.tx, patch.ty);
      final inHot = rect.overlaps(updateRect);
      if (!inHot) {
        if (updatePatchSlices > 1 && ((patchIdx - _patchCursor) % updatePatchSlices) != 0) {
          patchIdx++;
          return;
        }
      }
      patchIdx++;

      final ps = patch.puffs;
      for (int i = 0; i < ps.length; i++) {
        if (puffSlices > 1 && (i % puffSlices) != puffSliceIdx) continue;
        final p = ps[i];

        // ① 位移：基础速度 + 全局风
        p.worldPos.x += (p.vel.x + wind.x) * dt;
        p.worldPos.y += (p.vel.y + wind.y) * dt;

        // ② 呼吸：三角波（免三角函数）
        p.phase = (p.phase + p.pulseSpeed * dt) % 1.0;
        final tri = 1.0 - (2.0 * (p.phase - 0.5)).abs(); // 0..1..0
        final breathe = (tri - 0.5) * 2.0 * p.pulseAmp;  // -amp..+amp

        // ③ 吹散：sin(t + φ) 合成
        final gust = 0.5 + 0.5 * (sinTg * p.cG + cosTg * p.sG); // 0..1
        final disperse = gust * gustK;

        // 半径 = 基础 × (吹散) × (呼吸)
        p.curRadius = p.baseRadius * (1.0 + 0.9 * disperse) * (1.0 + 0.25 * breathe);

        // 透明度降低，但保底
        p.curAlpha = (p.baseAlpha * (1.0 - 0.75 * disperse)).clamp(alphaFloor, 1.0);

        // ④ 抖动方向：同理 sin/cos(tj + φ)
        final sinJ = sinTj * p.cG + cosTj * p.sG;
        final cosJ = cosTj * p.cG - sinTj * p.sG;
        final jMag = (2.0 + 6.0 * disperse) * dt;
        p.worldPos.x += cosJ * jMag;
        p.worldPos.y += sinJ * jMag;
      }
    });

    if (puffSlices > 1) _sliceCursor = (_sliceCursor + 1) % puffSlices;
    if (updatePatchSlices > 1) _patchCursor = (_patchCursor + 1) % updatePatchSlices;
  }

  _MistPatch _spawnPatch(int tx, int ty, String terrain, Rect rect, Random r) {
    // ✅ 先用缓存（避免来回生成带来的尖峰）
    final key = '${tx}_${ty}';
    if (cacheEnabled && _cache.containsKey(key)) {
      final tpl = _cache.remove(key)!;
      _cacheOrder.remove(key);
      final puffs = tpl.instantiateAt(rect.left, rect.top);
      return _MistPatch(tx: tx, ty: ty, puffs: puffs);
    }

    // 调色板
    final palette = (paletteResolver ?? _defaultPaletteForTerrain)(terrain);

    // 基数 → 受 density 调整
    final baseCount   = _randRangeInt(r, minPuffsPerTile, maxPuffsPerTile);
    final approxCount = (baseCount * (0.5 + 0.8 * density)).round().clamp(6, 999);

    final List<_Puff> puffs = <_Puff>[];

    if (wispyMode) {
      // —— 缕状雾（抗“长方块”）：角度抖动 + 步长<直径 + 中段更强 —— //
      // 基于风向的主方向，附加  ±0.25rad 抖动
      final baseDir = (globalWind.length2 > 1e-6)
          ? globalWind.normalized()
          : Vector2(cos(r.nextDouble() * pi * 2), sin(r.nextDouble() * pi * 2));
      final baseAngle = atan2(baseDir.y, baseDir.x);

      // 以平均半径确定“视觉直径”
      final avgRad = (puffRadiusMin + puffRadiusMax) * 0.5;
      final diam   = avgRad * 2;

      int remain = approxCount;
      while (remain > 0) {
        final len = r.nextInt(strandLenMax - strandLenMin + 1) + strandLenMin; // 3..6 段
        // 步长强制 < 直径（0.45~0.65）并受外部区间约束
        double sMin = max(diam * 0.45, strandStepMin);
        double sMax = min(diam * 0.65, strandStepMax);
        if (sMax <= sMin) sMax = sMin + 1.0;
        final step   = _randRange(r, sMin, sMax);
        final jitter = strandJitter;

        final rotJitter = (r.nextDouble() - 0.5) * 0.5; // ±0.25 rad
        final dir = Vector2(
          cos(baseAngle + rotJitter),
          sin(baseAngle + rotJitter),
        );
        final angle = atan2(dir.y, dir.x); // atlas 贴图朝向

        // 起点随机
        final start = Vector2(
          rect.left + r.nextDouble() * tileSize,
          rect.top  + r.nextDouble() * tileSize,
        );

        for (int j = 0; j < len && remain > 0; j++, remain--) {
          final t = len == 1 ? 0.5 : j / (len - 1);     // 0..1
          final pos = start + dir * (step * j) +
              Vector2((r.nextDouble() * 2 - 1) * jitter, (r.nextDouble() * 2 - 1) * jitter);

          // 颜色：低饱和微蓝 → 接近白雾；依然保留 cA/cB 供非 atlas 路线使用
          final aCol = palette[r.nextInt(palette.length)];
          final bCol = palette[r.nextInt(palette.length)];
          final tint = _mixColor(const Color(0xE6FFFFFF), const Color(0xCCF2F6FF), 0.18);

          // 速度：沿条带方向，轻微随机
          final spd = _randRange(r, speedMin, speedMax);
          final vel = dir * spd * (0.85 + 0.30 * r.nextDouble());

          // 头尾更细更淡，中段略强
          final shapeK = (1.0 - (t - 0.5).abs() * 1.15).clamp(0.0, 1.0);
          final rad = _randRange(r, puffRadiusMin, puffRadiusMax) * (0.6 + 0.6 * shapeK);
          final alp = _randRange(r, alphaMin,  alphaMax)          * (0.5 + 0.6 * shapeK);

          // 呼吸更稳定，避免“气泡跳”
          final pulseSpd = _randRange(r, pulseSpeedMin, pulseSpeedMax);
          final pulseAmp = _randRange(r, pulseAmpMin, min(pulseAmpMax, 0.14));

          final atlasVar = (_blobImgs == null || _blobImgs!.isEmpty) ? 0 : r.nextInt(_blobImgs!.length);
          final gp = r.nextDouble() * pi * 2; // gust 相位

          puffs.add(_Puff(
            worldPos: pos,
            vel: vel,
            baseRadius: rad,
            baseAlpha: alp,
            cA: aCol, cB: bCol, tint: tint,
            pulseSpeed: pulseSpd,
            pulseAmp: pulseAmp,
            phase: r.nextDouble(),     // 0..1
            sG: sin(gp), cG: cos(gp),  // 预计算，update 时免三角
            atlasVar: atlasVar,
            rot: angle,
            useGradient: useGradient,
            mixMode: mixMode,
          ));
        }
      }
    } else {
      // —— 点状原始逻辑（保留）——
      for (int i = 0; i < approxCount; i++) {
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

        final atlasVar = (_blobImgs == null || _blobImgs!.isEmpty) ? 0 : r.nextInt(_blobImgs!.length);
        final rot = r.nextDouble() * pi * 2;

        final tint = _mixColor(a, b, 0.35);
        final gp = r.nextDouble() * pi * 2;

        puffs.add(_Puff(
          worldPos: worldPos,
          vel: vel,
          baseRadius: rad,
          baseAlpha: alp,
          cA: a, cB: b, tint: tint,
          pulseSpeed: pulseSpd,
          pulseAmp: pulseAmp,
          phase: r.nextDouble(),
          sG: sin(gp), cG: cos(gp),
          atlasVar: atlasVar,
          rot: rot,
          useGradient: useGradient,
          mixMode: mixMode,
        ));
      }
    }

    return _MistPatch(tx: tx, ty: ty, puffs: puffs);
  }

  // ===== 渲染 =====
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cam = getLogicalOffset();

    if (useAtlas && _blobImgs != null && _blobImgs!.isNotEmpty) {
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.screen; // ✅ 提亮混合，更像真实薄雾

      for (int v = 0; v < _blobImgs!.length; v++) {
        _atlTransforms[v].clear();
        _atlRects[v].clear();
        _atlColors[v].clear();
      }

      for (final patch in _patches.values) {
        for (final p in patch.puffs) {
          final v = p.atlasVar;
          if (v < 0 || v >= _blobImgs!.length) continue;

          final src = _srcRects[v];
          final localX = p.worldPos.x - cam.x;
          final localY = p.worldPos.y - cam.y;
          final r = (p.curRadius ?? p.baseRadius).toDouble();
          final a = (p.curAlpha ?? p.baseAlpha).toDouble();

          _atlTransforms[v].add(ui.RSTransform.fromComponents(
            rotation: p.rot,
            scale: (r * 2) / src.width,
            anchorX: src.width / 2, anchorY: src.height / 2,
            translateX: localX, translateY: localY,
          ));
          _atlRects[v].add(src);
          final aa = (a * 255).clamp(0, 255).toInt();
          _atlColors[v].add(Color((aa << 24) | (p.tint.value & 0x00FFFFFF)));
        }
      }

      for (int v = 0; v < _blobImgs!.length; v++) {
        if (_atlTransforms[v].isEmpty) continue;
        canvas.drawAtlas(
          _blobImgs![v], _atlTransforms[v], _atlRects[v], _atlColors[v],
          BlendMode.modulate, // 注意：颜色仍用 modulate 乘色，最终以 screen 与背景融合
          null, paint,
        );
      }
      return;
    }

    // —— 原始渲染路径（逐个 gradient/solid）——
    for (final patch in _patches.values) {
      for (final p in patch.puffs) {
        final localX = p.worldPos.x - cam.x;
        final localY = p.worldPos.y - cam.y;
        final r = p.curRadius ?? p.baseRadius;
        final a = p.curAlpha ?? p.baseAlpha;

        if (useGradient) {
          final shader = ui.Gradient.radial(
            Offset(localX, localY), r.toDouble(),
            [_mixColor(p.cA, p.cB, 0.0).withOpacity(a),
              _mixColor(p.cA, p.cB, 1.0).withOpacity(0.0)],
            const [0.0, 1.0],
          );
          final paint = Paint()
            ..shader = shader
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..blendMode = BlendMode.screen; // ✅ 同样用 screen
          canvas.drawCircle(Offset(localX, localY), r.toDouble(), paint);
        } else {
          final color = _mixColor(p.cA, p.cB, 0.35).withOpacity(a);
          final paint = Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
            ..blendMode = BlendMode.screen;
          canvas.drawCircle(Offset(localX, localY), r.toDouble(), paint);
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
        return const [Color(0xB3FFFFFF), Color(0x99F2F6FF), Color(0x80EAF2FF)];
      case 'swamp':
        return const [Color(0x99F0FFF0), Color(0x80E0F5E0)];
      case 'desert':
      case 'sand':
        return const [Color(0x99FFFDF2), Color(0x80FFF7E6)];
      case 'snow':
      case 'ice':
        return const [Color(0xCCFFFFFF), Color(0x99F4FBFF)];
      case 'lava':
      case 'volcano':
        return const [Color(0x80FFE6E6), Color(0x66FFD1B8)];
      case 'water':
      case 'lake':
      case 'river':
      case 'shallow_ocean':
        return const [Color(0xB3FFFFFF), Color(0x99E7F6FF), Color(0x80DFF2FF)];
      case 'mountain':
      case 'rock':
        return const [Color(0xB3FFFFFF), Color(0x80EDEFF2)];
      default:
        return const [Color(0xB3FFFFFF), Color(0x99F2F6FF)];
    }
  }

  // ===== 小工具 =====
  static double _randRange(Random r, double a, double b) => a + r.nextDouble() * (b - a);
  static int _randRangeInt(Random r, int a, int b) =>
      a + r.nextInt((b - a + 1).clamp(1, 1 << 30));

  // 颜色混合（给 atlas tint 用；useAtlas 时只在构建期调用一次/雾团）
  Color _mixColor(Color cA, Color cB, double t) {
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

  // —— 软圆（备用） —— //
  Future<ui.Image> _makeSoftCircle(int size) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final center = Offset(size / 2, size / 2);
    final r = size / 2 - 1;
    final shader = ui.Gradient.radial(
      center, r, const [Colors.white, Colors.transparent], const [0.0, 1.0],
    );
    c.drawCircle(center, r, Paint()..shader = shader);
    final pic = rec.endRecording();
    return await pic.toImage(size, size);
  }

  // —— 有机云（metaball） —— //
  Future<ui.Image> _makeSoftBlob(int size, int seed) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rng = Random(seed);

    final center = Offset(size / 2, size / 2);
    final baseR  = size / 2 - 1;

    final outer = Paint()
      ..shader = ui.Gradient.radial(
        center, baseR,
        [Colors.white.withOpacity(0.22), Colors.transparent],
        const [0.0, 1.0],
      );
    c.drawCircle(center, baseR, outer);

    final lobes = 4 + rng.nextInt(3);
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

  // —— 丝状雾贴图 —— //
  Future<ui.Image> _makeWispyBlob(int size, int seed, {double aniso = 1.8}) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rng = Random(seed);

    final pad = 2.0;                         // ✅ 更大的透明边，防止出血
    final center = Offset(size / 2, size / 2);
    final len    = size * (0.62 + rng.nextDouble() * 0.08); // 胶囊长度
    final rad    = size * (0.22 + rng.nextDouble() * 0.06); // 胶囊短半径
    final steps  = 9;                         // 用多圆叠加成柔和“胶囊”
    final step   = (len - rad * 2) / (steps - 1);

    c.save();
    c.translate(center.dx, center.dy);
    c.scale(aniso, 1.0);                      // 适度拉长，不要太夸张
    c.translate(-center.dx, -center.dy);

    // 端帽：两头更亮，中间略淡，避免长方块
    for (int i = 0; i < steps; i++) {
      final t  = steps == 1 ? 0.5 : i / (steps - 1);
      final x  = center.dx - (len / 2 - rad) + i * step;
      final y  = center.dy + (rng.nextDouble() * 2 - 1) * size * 0.015;
      final k  = 1.0 - (t - 0.5).abs() * 1.2;                // 中段更强，头尾更弱
      final rr = rad * (0.85 + 0.35 * k);
      final op = 0.20 + 0.22 * k;

      final p = Paint()
        ..shader = ui.Gradient.radial(
          Offset(x, y), rr,
          [Colors.white.withOpacity(op), Colors.transparent],
          const [0.0, 1.0],
        );
      c.drawCircle(Offset(x, y), rr, p);
    }

    // 超淡的整体柔边
    final edge = Paint()
      ..shader = ui.Gradient.radial(
        center, size * 0.49,
        [Colors.white.withOpacity(0.08), Colors.transparent],
        const [0.0, 1.0],
      );
    c.drawCircle(center, size * 0.49, edge);

    c.restore();

    final pic = rec.endRecording();
    return await pic.toImage(size, size);
  }

  // ====== 缓存 LRU ======
  void _pushCache(String key, _PuffTemplateList tpl) {
    _cache[key] = tpl;
    _cacheOrder.addLast(key);
    while (_cacheOrder.length > cacheCap) {
      final old = _cacheOrder.removeFirst();
      _cache.remove(old);
    }
  }
}

// ===== 内部结构 =====
class _MistPatch {
  final int tx, ty;
  final List<_Puff> puffs;
  double _lastInsideTime = 0;
  _MistPatch({required this.tx, required this.ty, required this.puffs});
}

class _Puff {
  Vector2 worldPos;   // 世界系坐标
  Vector2 vel;        // 自身基础速度
  double baseRadius;  // 基础半径
  double baseAlpha;   // 基础透明度
  double? curRadius;  // 动态半径
  double? curAlpha;   // 动态不透明度
  final Color cA, cB;
  final Color tint;   // atlas 预计算 tint
  double pulseSpeed;  // 呼吸速度（三角波）
  double pulseAmp;    // 呼吸幅度（0..1）
  double phase;       // 0..1
  final double sG;    // sin(gustPhase)
  final double cG;    // cos(gustPhase)

  // atlas 变体 & 旋转
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
    required this.tint,
    required this.pulseSpeed,
    required this.pulseAmp,
    required this.phase,
    required this.sG,
    required this.cG,
    this.atlasVar = 0,
    this.rot = 0.0,
    required this.useGradient,
    required this.mixMode,
  });
}

// —— 缓存模板（相对 tile 左上角）——
class _PuffTemplate {
  final double rx, ry;     // 相对坐标
  final double vx, vy;
  final double baseRadius;
  final double baseAlpha;
  final Color cA, cB;
  final Color tint;
  final double pulseSpeed, pulseAmp, phase;
  final double sG, cG;
  final int atlasVar;
  final double rot;
  final bool useGradient;
  final MistMixMode mixMode;

  _PuffTemplate({
    required this.rx, required this.ry,
    required this.vx, required this.vy,
    required this.baseRadius, required this.baseAlpha,
    required this.cA, required this.cB, required this.tint,
    required this.pulseSpeed, required this.pulseAmp, required this.phase,
    required this.sG, required this.cG,
    required this.atlasVar, required this.rot,
    required this.useGradient, required this.mixMode,
  });

  _Puff instantiateAt(double ox, double oy) {
    return _Puff(
      worldPos: Vector2(ox + rx, oy + ry),
      vel: Vector2(vx, vy),
      baseRadius: baseRadius,
      baseAlpha: baseAlpha,
      cA: cA, cB: cB, tint: tint,
      pulseSpeed: pulseSpeed, pulseAmp: pulseAmp, phase: phase,
      sG: sG, cG: cG,
      atlasVar: atlasVar, rot: rot,
      useGradient: useGradient, mixMode: mixMode,
    );
  }
}

class _PuffTemplateList {
  final List<_PuffTemplate> list;
  _PuffTemplateList(this.list);

  factory _PuffTemplateList.fromPatch(_MistPatch p, double tileSize) {
    final res = <_PuffTemplate>[];
    final ox = p.tx * tileSize;
    final oy = p.ty * tileSize;
    for (final e in p.puffs) {
      res.add(_PuffTemplate(
        rx: e.worldPos.x - ox, ry: e.worldPos.y - oy,
        vx: e.vel.x, vy: e.vel.y,
        baseRadius: e.baseRadius, baseAlpha: e.baseAlpha,
        cA: e.cA, cB: e.cB, tint: e.tint,
        pulseSpeed: e.pulseSpeed, pulseAmp: e.pulseAmp, phase: e.phase,
        sG: e.sG, cG: e.cG,
        atlasVar: e.atlasVar, rot: e.rot,
        useGradient: e.useGradient, mixMode: e.mixMode,
      ));
    }
    return _PuffTemplateList(res);
  }

  List<_Puff> instantiateAt(double ox, double oy) =>
      list.map((t) => t.instantiateAt(ox, oy)).toList(growable: false);
}
