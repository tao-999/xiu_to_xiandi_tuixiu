import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// 一段雷链电弧：start -> end（折线抖动 + 分叉根须 + 淡出）
/// 说明：这里接收的坐标应当是“父层本地坐标”（已在 VfxLightningChain 里做了世界->本地转换）
class VfxLightningBolt extends PositionComponent with HasGameReference {
  // ===== 主体参数 =====
  final Vector2 localEnd;
  final double life;          // 主干显示时长
  final double fadeOut;       // 主干淡出时长
  final double thickness;     // 主干线宽
  final double jaggedness;    // 主干抖动幅度（px）
  final int segments;         // 主干细分段数
  final Color color;          // 颜色
  final int? seed;
  final int? basePriority;

  // ===== 分叉（根须）参数 =====
  final double forkChance;         // 每个主干段生成分叉的概率（0~1）
  final double forkLengthMin;      // 分叉长度区间（px）
  final double forkLengthMax;
  final double forkLifeScale;      // 分叉寿命 = life * scale
  final double forkFadeScale;      // 分叉淡出 = fadeOut * scale
  final double forkThicknessScale; // 分叉线宽 = thickness * scale
  final double forkAngleJitterDeg; // 分叉法线方向的角度抖动（±度）
  final int    forkSegmentsMin;    // 分叉折线最小段数
  final int    forkSegmentsMax;    // 分叉折线最大段数
  final double forwardBias;        // 分叉沿主干切向前伸的偏置系数（0~0.4 推荐）

  double _t = 0;

  late final List<Vector2> _main;                 // 主干折线点（本地坐标）
  late final List<List<Vector2>> _forks;          // 分叉折线组（本地坐标）
  late final Random _rng;

  VfxLightningBolt({
    required Vector2 startWorld,
    required Vector2 endWorld,

    // 主干
    this.life = 0.08,
    this.fadeOut = 0.12,
    this.thickness = 2.6,
    this.jaggedness = 10,
    this.segments = 18,
    this.color = const Color(0xFFB5E2FF),

    // 分叉（“根须感”关键）
    this.forkChance = 0.28,
    this.forkLengthMin = 14,
    this.forkLengthMax = 46,
    this.forkLifeScale = 0.60,
    this.forkFadeScale = 0.65,
    this.forkThicknessScale = 0.60,
    this.forkAngleJitterDeg = 28,
    this.forkSegmentsMin = 4,
    this.forkSegmentsMax = 8,
    this.forwardBias = 0.12,

    this.seed,
    this.basePriority,
  }) : localEnd = endWorld - startWorld {
    position = startWorld.clone();   // 组件原点 = 起点
    anchor = Anchor.topLeft;
    if (basePriority != null) priority = basePriority!;
    _rng = Random(seed);

    _generateMainPolyline();
    _generateForks();
  }

  // ===== 折线生成 =====
  void _generateMainPolyline() {
    final len = localEnd.length;
    final dir = len == 0 ? Vector2(1, 0) : localEnd / len;
    final nrm = Vector2(-dir.y, dir.x);

    _main = List.generate(segments + 1, (i) {
      final t = i / segments;
      final along = len * t;
      final falloff = sin(pi * t); // 中段抖动最大
      final offset = (_rng.nextDouble() * 2 - 1) * jaggedness * falloff;
      // ⛏ 注意括号，避免级联优先级问题
      return (Vector2(dir.x, dir.y)..scale(along)) + nrm * offset;
    });
    _main.first = Vector2.zero();
    _main.last = localEnd.clone();
  }

  void _generateForks() {
    _forks = <List<Vector2>>[];
    if (_main.length < 3) return;

    for (int i = 1; i < _main.length - 1; i++) {
      if (_rng.nextDouble() > forkChance) continue;

      final prev = _main[i - 1];
      final cur  = _main[i];
      final next = _main[i + 1];

      final tangent = (next - prev);
      if (tangent.length2 == 0) continue;
      final tDir = tangent.normalized();

      // 基础法线，左右随机
      Vector2 nrm = Vector2(-tDir.y, tDir.x);
      if (_rng.nextBool()) nrm = -nrm;

      // 抖动角度
      final jitterRad = (forkAngleJitterDeg * pi / 180.0) *
          (_rng.nextDouble() * 2 - 1);
      nrm.rotate(jitterRad);

      final len = _rng.nextDouble() * (forkLengthMax - forkLengthMin) + forkLengthMin;

      // 沿法线伸展 + 少许切向前伸（让分叉有前倾感）
      final baseDir = nrm.normalized();
      final branchTangentBias = tDir * (len * forwardBias);

      // 生成分叉折线
      final segCnt = _rng.nextInt(forkSegmentsMax - forkSegmentsMin + 1) + forkSegmentsMin;
      final List<Vector2> branch = List.generate(segCnt + 1, (k) {
        final u = k / segCnt;
        final along = len * u;

        // 抖动随距离端点逐渐减小
        final falloff = 1.0 - u; // 末端更细更稳
        final sideJitter = (_rng.nextDouble() * 2 - 1) *
            (jaggedness * 0.6) * falloff;

        // 基向量（法线方向）
        final p = cur +
            baseDir * along +   // 法线伸展
            branchTangentBias * u; // 切向偏移

        final bNrm = Vector2(-baseDir.y, baseDir.x);
        return p + bNrm * sideJitter;
      });

      _forks.add(branch);
    }
  }

  // ===== 渲染 =====
  double _alphaFor(double life_, double fade_) {
    final total = life_ + fade_;
    final k = (_t / total).clamp(0.0, 1.0);
    final mid = life_ / total;
    return k < mid ? 1.0 : (1 - (k - mid) / (1 - mid));
  }

  @override
  void render(Canvas canvas) {
    // 主干透明度
    final aMain = _alphaFor(life, fadeOut);

    // —— 主干 Path —— //
    final mainPath = Path()..moveTo(_main[0].x, _main[0].y);
    for (int i = 1; i < _main.length; i++) {
      mainPath.lineTo(_main[i].x, _main[i].y);
    }

    // 外发光（主干）
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 2.2
      ..color = color.withOpacity(0.25 * aMain);
    canvas.drawPath(mainPath, glow);

    // 主干核心线
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = color.withOpacity(aMain);
    canvas.drawPath(mainPath, core);

    // —— 分叉（根须） —— //
    final aFork = _alphaFor(life * forkLifeScale, fadeOut * forkFadeScale);
    if (aFork > 0.0 && _forks.isNotEmpty) {
      final forkStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (thickness * forkThicknessScale).clamp(0.8, thickness)
        ..color = color.withOpacity(0.85 * aFork);
      final forkGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (thickness * forkThicknessScale * 1.8)
        ..color = color.withOpacity(0.18 * aFork);

      for (final br in _forks) {
        final p = Path()..moveTo(br[0].x, br[0].y);
        for (int i = 1; i < br.length; i++) {
          p.lineTo(br[i].x, br[i].y);
        }
        canvas.drawPath(p, forkGlow);  // 先发光
        canvas.drawPath(p, forkStroke); // 后描线
      }
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= life + fadeOut) removeFromParent();
  }
}
