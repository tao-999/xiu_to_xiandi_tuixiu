// 📂 lib/widgets/effects/vfx_world_lightning_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/noise_tile_map_generator.dart';

class WorldLightningLayer extends Component {
  // ===== 外部环境 =====
  final Component grid;
  final Vector2 Function() getLogicalOffset; // 世界相机中心
  final Vector2 Function() getViewSize;      // 画布尺寸
  final String Function(Vector2) getTerrainType;
  final NoiseTileMapGenerator? noiseMapGenerator;

  // ===== Tile 配置 =====
  final double tileSize;
  final int seed;
  final Set<String> volcanicTerrains;

  // ===== 调度/性能 =====
  final double tilesFps;              // 扫描/生成/卸载 频率（<=0 每帧）
  final int maxConcurrentStrikes;     // 单 tile 同时闪电数量上限
  double _accTiles = 0;

  // ===== 行为参数 =====
  final double strikeIntervalMin;     // 同 tile 两次闪电间隔
  final double strikeIntervalMax;
  final double boltLifespan;          // 亮闪时间
  final double afterglow;             // 余辉时间（总消退时间 = lifespan+afterglow）
  final double branchProb;            // 产生分支概率
  final double branchDecay;           // 分支能量衰减（宽度/亮度）
  final int    fractalDepth;          // 形状复杂度（2~5）
  final double jitter;                // 中点位移强度（px）
  final double forkAngle;             // 分支偏转角（弧度）
  final double boltWidthMin;          // 核心宽
  final double boltWidthMax;          // 核心宽
  final double glowWidthMul;          // 辉光宽度倍率

  // ===== 颜色（单色 & 多色调色板同时支持） =====
  final Color coreColor;              // 单色核心（作为调色板兜底）
  final Color glowColor;              // 单色辉光（作为调色板兜底）
  final List<Color> corePalette;      // 多色核心调色板（可空，空时用 coreColor）
  final List<Color> glowPalette;      // 多色辉光调色板（可空，空时用 glowColor）
  final double coreAlpha;             // 核心不透明度
  final double glowAlpha;             // 辉光不透明度

  // ===== 内部状态 =====
  final Map<String, _LightningTile> _tiles = {};
  double _time = 0;

  WorldLightningLayer({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.getTerrainType,
    this.noiseMapGenerator,
    this.tileSize = 128.0,
    this.seed = 4242,
    this.volcanicTerrains = const {'volcano','volcanic','lava'},

    // 调度/性能
    this.tilesFps = 10.0,
    this.maxConcurrentStrikes = 2,

    // 行为
    this.strikeIntervalMin = 2.0,
    this.strikeIntervalMax = 6.0,
    this.boltLifespan = 0.18,
    this.afterglow = 0.22,
    this.branchProb = 0.45,
    this.branchDecay = 0.55,
    this.fractalDepth = 3,
    this.jitter = 18.0,
    this.forkAngle = 0.7,
    this.boltWidthMin = 1.8,
    this.boltWidthMax = 3.6,
    this.glowWidthMul = 3.2,

    // 颜色
    this.coreColor = const Color(0xFFFFFFFF),
    this.glowColor = const Color(0xFF7FDBFF),
    List<Color>? corePalette,
    List<Color>? glowPalette,
    this.coreAlpha = 0.95,
    this.glowAlpha = 0.45,
  })  : corePalette = corePalette ?? const [],
        glowPalette = glowPalette ?? const [];

  // —— 工具：统一地形口径 ——
  String _classify(Vector2 p) {
    if (noiseMapGenerator != null) {
      return noiseMapGenerator!.getTerrainTypeAtPosition(p);
    }
    return getTerrainType(p);
  }

  // —— 可视×1.25 的保留矩形（世界系） ——
  Rect _keepRect(Vector2 center, Vector2 view) {
    final keep = view * 1.25;
    final tl = center - keep / 2;
    return Rect.fromLTWH(tl.x, tl.y, keep.x, keep.y);
  }

  Rect _tileRect(int tx, int ty) =>
      Rect.fromLTWH(tx * tileSize, ty * tileSize, tileSize, tileSize);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final cam = getLogicalOffset();
    final view = getViewSize();
    final keep = _keepRect(cam, view);

    // —— 1) 生成/卸载（节流） ——
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
      final sx = (keep.left / tileSize).floor();
      final sy = (keep.top  / tileSize).floor();
      final ex = (keep.right / tileSize).ceil();
      final ey = (keep.bottom/ tileSize).ceil();

      for (int tx = sx; tx < ex; tx++) {
        for (int ty = sy; ty < ey; ty++) {
          final rect = _tileRect(tx, ty);
          if (!rect.overlaps(keep)) continue;

          final center = Vector2(rect.center.dx, rect.center.dy);
          final terr = _classify(center);
          if (!volcanicTerrains.contains(terr)) continue;

          final key = '${tx}_$ty';
          var t = _tiles[key];
          if (t == null) {
            final r = Random(seed ^ (tx * 92821) ^ (ty * 53987) ^ 0x9E3779B9);
            t = _LightningTile(
              tx: tx,
              ty: ty,
              rng: r,
              nextStrikeAt: _time + _randRange(r, strikeIntervalMin, strikeIntervalMax),
            );
            _tiles[key] = t;
          }
        }
      }

      // 卸载不在 keep 的 tile
      final drop = <String>[];
      _tiles.forEach((key, t) {
        final rect = _tileRect(t.tx, t.ty);
        if (!rect.overlaps(keep)) drop.add(key);
      });
      for (final k in drop) {
        _tiles.remove(k);
      }
    }

    // —— 2) 调度每个 tile 的闪电 & 更新现存闪电 ——
    _tiles.forEach((_, t) {
      // 到时间就生成新的闪电（受并发限制）
      if (_time >= t.nextStrikeAt && t.strikes.length < maxConcurrentStrikes) {
        final rect = _tileRect(t.tx, t.ty);
        final s = _spawnStrikeInRect(rect, t.rng);
        t.strikes.add(s);
        // 计划下一次
        t.nextStrikeAt = _time + _randRange(t.rng, strikeIntervalMin, strikeIntervalMax);
      }

      // 回收过期
      t.strikes.removeWhere((s) => (_time - s.birth) > (boltLifespan + afterglow));
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 相机转换为 Offset
    final camV = getLogicalOffset();
    final cam  = Offset(camV.x, camV.y);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 6);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final t in _tiles.values) {
      for (final s in t.strikes) {
        final age = _time - s.birth;
        final life = boltLifespan + afterglow;
        double k = (1.0 - (age / life)).clamp(0.0, 1.0); // 0..1

        final brightPhase = (age <= boltLifespan);
        final coreA = (brightPhase ? coreAlpha : coreAlpha * 0.35) * k;
        final glowA = (brightPhase ? glowAlpha : glowAlpha * 0.25) * k;

        final coreW = _lerp(s.width, s.width * 0.7, age / life);
        final glowW = coreW * glowWidthMul;

        // 画分支（先辉光后内核）
        for (final br in s.branches) {
          final path = ui.Path();
          final first = br.points.first - cam;
          path.moveTo(first.dx, first.dy);
          for (int i = 1; i < br.points.length; i++) {
            final p = br.points[i] - cam;
            path.lineTo(p.dx, p.dy);
          }

          glowPaint..color = s.glow.withOpacity(glowA);
          glowPaint.strokeWidth = glowW * br.intensity;
          canvas.drawPath(path, glowPaint);

          corePaint..color = s.core.withOpacity(coreA);
          corePaint.strokeWidth = coreW * br.intensity;
          canvas.drawPath(path, corePaint);
        }
      }
    }
  }

  // ====== 生成一条闪电（含分支） ======
  _Strike _spawnStrikeInRect(Rect rect, Random rng) {
    // 终点在 tile 内，起点在 tile 顶上方的“云层”
    final end = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    final start = Offset(
      end.dx + _randRange(rng, -rect.width * 0.15, rect.width * 0.15),
      rect.top - _randRange(rng, rect.height * 0.8, rect.height * 1.6),
    );

    final width = _randRange(rng, boltWidthMin, boltWidthMax);

    // 主干
    final main = _buildBranch(
      rng: rng,
      from: start,
      to: end,
      depth: fractalDepth,
      jitter: jitter,
      intensity: 1.0,
    );

    // 分支集合
    final branches = <_Branch>[main];
    _spawnForks(
      rng: rng,
      base: main,
      depthLeft: 2,
      intensity: branchDecay,
      out: branches,
    );

    // —— 颜色：从调色板随机挑；没给调色板就用单色兜底 ——
    final List<Color> cp = corePalette.isNotEmpty ? corePalette : [coreColor];
    final List<Color> gp = glowPalette.isNotEmpty ? glowPalette : [glowColor];
    final cCore = cp[rng.nextInt(cp.length)];
    final cGlow = gp[rng.nextInt(gp.length)];

    return _Strike(
      birth: _time,
      width: width,
      branches: branches,
      core: cCore,
      glow: cGlow,
    );
  }

  // 分形中点位移生成折线
  _Branch _buildBranch({
    required Random rng,
    required Offset from,
    required Offset to,
    required int depth,
    required double jitter,
    required double intensity,
  }) {
    List<Offset> pts = [from, to];
    double amp = jitter;
    for (int d = 0; d < depth; d++) {
      final next = <Offset>[];
      for (int i = 0; i < pts.length - 1; i++) {
        final a = pts[i];
        final b = pts[i + 1];
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

        // 与 AB 垂直方向抖动
        final dir = Offset(b.dy - a.dy, -(b.dx - a.dx));
        final len = sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
        final n = (len == 0) ? const Offset(0, 0) : Offset(dir.dx / len, dir.dy / len);

        final disp = _randRange(rng, -amp, amp);
        final m2 = Offset(mid.dx + n.dx * disp, mid.dy + n.dy * disp);

        next..add(a)..add(m2);
      }
      next.add(pts.last);
      pts = next;
      amp *= 0.55; // 逐层减小抖动
    }
    return _Branch(points: pts, intensity: intensity);
  }

  // 从主干上产生分支（有限层）
  void _spawnForks({
    required Random rng,
    required _Branch base,
    required int depthLeft,
    required double intensity,
    required List<_Branch> out,
  }) {
    if (depthLeft <= 0 || intensity < 0.15) return;

    final pts = base.points;
    for (int i = 1; i < pts.length - 1; i++) {
      if (rng.nextDouble() > branchProb) continue;

      final p = pts[i];
      // 朝下分支，基于主干方向略偏转
      final idxB = min(i + 1, pts.length - 1);
      final dir = (pts[idxB] - p);
      final dlen = sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
      if (dlen == 0) continue;

      final dx = dir.dx / dlen, dy = dir.dy / dlen;
      // 旋转 +/- forkAngle
      final sign = rng.nextBool() ? 1.0 : -1.0;
      final ca = cos(forkAngle * sign), sa = sin(forkAngle * sign);
      final fx = dx * ca - dy * sa;
      final fy = dx * sa + dy * ca;

      final len = _randRange(rng, 40, 120) * intensity;
      final q = Offset(p.dx + fx * len, p.dy + fy * len);

      final br = _buildBranch(
        rng: rng,
        from: p,
        to: q,
        depth: max(1, fractalDepth - 1),
        jitter: jitter * 0.6,
        intensity: intensity,
      );
      out.add(br);

      // 递归更细的分支
      _spawnForks(
        rng: rng,
        base: br,
        depthLeft: depthLeft - 1,
        intensity: intensity * branchDecay,
        out: out,
      );
    }
  }

  // 工具
  static double _randRange(Random r, double a, double b) => a + r.nextDouble() * (b - a);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ===== 内部结构 =====
class _LightningTile {
  final int tx, ty;
  final Random rng;
  double nextStrikeAt;
  final List<_Strike> strikes = [];
  _LightningTile({
    required this.tx,
    required this.ty,
    required this.rng,
    required this.nextStrikeAt,
  });
}

class _Strike {
  final double birth;
  final double width;             // 主干基础宽度
  final List<_Branch> branches;   // 主干+分支集合
  final Color core;               // 此道闪电的核心色
  final Color glow;               // 此道闪电的辉光色
  _Strike({
    required this.birth,
    required this.width,
    required this.branches,
    required this.core,
    required this.glow,
  });
}

class _Branch {
  final List<Offset> points;      // 世界系
  final double intensity;         // 对宽度/亮度的倍率（分支更细更淡）
  _Branch({required this.points, required this.intensity});
}
