// 📂 lib/widgets/effects/vfx_world_rain_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/infinite_grid_painter_component.dart';
import '../components/noise_tile_map_generator.dart';

/// 用法：
/// final rain = WorldRainLayer(intensity: 0.7, wind: Vector2(-120, 520))
///   ..priority = 1150;
/// _grid!.add(rain);
class WorldRainLayer extends Component with HasGameReference<FlameGame> {
  // —— 可调口味 ——（默认已很像真雨）
  final double tileSize;        // 生成/管理网格
  final double keepFactor;      // 生成/卸载范围倍数（1.0=仅可视区）
  final double tilesFps;        // 扫描/生成/卸载频率（<=0 每帧）
  final double intensity;       // 0..1 雨量：影响密度/速度/亮度
  final Vector2 wind;           // 世界风向（px/s），决定雨斜
  final int    updateSlices;    // 分帧更新（1=关闭）
  final bool   clipToView;      // 仅在可视区域内渲染

  // 批渲染纹理（细长雨丝；注意：atlas 统一缩放，所以基底做很细）
  final bool useAtlas;
  final int atlasW;             // 纹理宽：越小越细（建议 6~10）
  final int atlasH;             // 纹理高：建议 48~96

  // —— 内部状态 ——
  late InfiniteGridPainterComponent _grid;
  late NoiseTileMapGenerator _noise;
  final Map<String, _RainPatch> _patches = {};
  double _t = 0;
  double _accTiles = 0;
  int _sliceCursor = 0;

  ui.Image? _streakImg;

  WorldRainLayer({
    this.tileSize = 256.0,
    this.keepFactor = 1.0,
    this.tilesFps = 12.0,
    this.intensity = 0.6,
    Vector2? wind,
    this.updateSlices = 2,
    this.clipToView = true,

    // 批渲染：方的纹理会变“光柱”，所以我们做成 很窄×较高 的贴图
    this.useAtlas = true,
    this.atlasW = 8,
    this.atlasH = 64,
  }) : wind = wind ?? Vector2(-80, 520);

  @override
  Future<void> onLoad() async {
    final g = parent as InfiniteGridPainterComponent?;
    if (g == null) return;
    _grid = g;
    _noise = g.generator;

    // 预烘焙“细长渐隐雨丝”纹理
    _streakImg = await _makeStreak(atlasW, atlasH);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    final cam = _noise.logicalOffset;
    final view = game.size;
    final keep = _keepRect(cam, view);

    // —— 1) 生成/卸载（节流） ——
    bool doTiles = true;
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

          // 密度：基于强度和面积补偿（128^2 为基准）
          final r = Random(_noise.seed ^ (tx*92821) ^ (ty*53987) ^ 0x51F15EED);
          final base = 42; // 基准密度（适中）
          final areaK = (tileSize * tileSize) / (128.0 * 128.0);
          final count = max(8, (base * areaK * (0.35 + 1.10 * intensity)).round());

          final rect = _tileRect(tx, ty);
          final drops = <_Drop>[];
          for (int i = 0; i < count; i++) {
            // 长度/速度/亮度：随强度提升，但保持较低不透明度
            final len   = _randRange(r, 22.0, 60.0) * (0.8 + 1.2 * intensity);
            final speed = _randRange(r, 520.0, 980.0) * (0.75 + 0.8 * intensity);
            final alpha = _randRange(r, 0.06, 0.18) * (0.7 + 0.8 * intensity);
            final width = _randRange(r, 0.6, 1.2); // 线宽只影响非 atlas 路径

            final p = Vector2(
              rect.left + r.nextDouble() * rect.width,
              rect.top  + r.nextDouble() * rect.height,
            );

            // 竖直向下 + 风向
            final v = Vector2(0, speed) + wind;

            drops.add(_Drop(worldPos: p, vel: v, length: len, width: width, alpha: alpha));
          }
          _patches[key] = _RainPatch(tx: tx, ty: ty, drops: drops);
        }
      }

      // 回收超出 keep 的 tile
      final toRemove = <String>[];
      _patches.forEach((k, p) {
        final rect = _tileRect(p.tx, p.ty);
        if (!rect.overlaps(keep)) toRemove.add(k);
      });
      for (final k in toRemove) {
        _patches.remove(k);
      }
    }

    // —— 2) 更新（分帧） ——
    final slices = updateSlices <= 1 ? 1 : updateSlices;
    final sliceIdx = _sliceCursor;

    _patches.forEach((_, patch) {
      int idx = 0;
      for (final d in patch.drops) {
        if (slices > 1 && (idx++ % slices) != sliceIdx) continue;

        d.worldPos += d.vel * dt;

        // 流出 keep 底部则从顶部回灌
        if (d.worldPos.y > keep.bottom + 24) {
          d.worldPos
            ..y = keep.top - 12
            ..x += (d.vel.x * dt * 0.5) + (_hashJitter(d, 7) - 0.5) * 18;
        }
      }
    });

    if (slices > 1) _sliceCursor = (_sliceCursor + 1) % slices;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // —— 仅在可视区域内渲染 ——（坐标原点在相机中心）
    if (clipToView) {
      final v = game.size;
      canvas.save();
      canvas.clipRect(Rect.fromCenter(center: Offset.zero, width: v.x, height: v.y));
    }

    final cam = _noise.logicalOffset;

    if (useAtlas && _streakImg != null) {
      final img = _streakImg!;
      final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final paint = Paint()..filterQuality = FilterQuality.high;

      // 分批：收集所有变换后一次性 drawAtlas
      final transforms = <ui.RSTransform>[];
      final rects = <ui.Rect>[];
      final colors = <Color>[];

      _patches.forEach((_, patch) {
        for (final d in patch.drops) {
          final local = d.worldPos - cam;
          // 旋转到速度方向（纹理默认竖直，头上尾下）
          final ang = atan2(d.vel.y, d.vel.x) - pi/2;
          // 使用统一缩放：按“长度”缩放，宽度由纹理本身提供（非常细）
          final scale = (d.length / src.height).clamp(0.4, 3.0);

          transforms.add(ui.RSTransform.fromComponents(
            rotation: ang,
            scale: scale,
            anchorX: src.width / 2, anchorY: src.height * 0.8, // 头部更亮，anchor靠近尾端
            translateX: local.x, translateY: local.y,
          ));
          rects.add(src);
          colors.add(Colors.white.withOpacity(d.alpha)); // 调制透明度
        }
      });

      if (transforms.isNotEmpty) {
        canvas.drawAtlas(img, transforms, rects, colors, BlendMode.plus, null, paint);
      }
    } else {
      // 逐条线渲染（没 atlas 时的兜底）
      final pCore = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final pGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 1.5);

      _patches.forEach((_, patch) {
        for (final d in patch.drops) {
          final local = d.worldPos - cam;
          final dir = d.vel.normalized();
          final tail = Offset(local.x, local.y);
          final head = Offset(local.x - dir.x * d.length, local.y - dir.y * d.length);

          pGlow
            ..color = Colors.white.withOpacity(d.alpha * 0.28)
            ..strokeWidth = (d.width * 1.8).clamp(0.8, 2.2);
          canvas.drawLine(head, tail, pGlow);

          pCore
            ..color = Colors.white.withOpacity(d.alpha * 0.85)
            ..strokeWidth = d.width.clamp(0.5, 1.4);
          canvas.drawLine(head, tail, pCore);
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

  static double _randRange(Random r, double a, double b) => a + r.nextDouble() * (b - a);

  // 非对称亮度的细长“雨丝”（头亮尾淡，极窄，避免光柱感）
  Future<ui.Image> _makeStreak(int w, int h) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    // 背景透明，画一个竖直的圆头矩形
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH((w - 2) / 2, h * 0.05, 2.0, h * 0.90),
      const Radius.circular(1.2),
    );

    // 线性渐变：头部更亮、尾部更淡
    final shader = ui.Gradient.linear(
      Offset(w/2, h * 0.05),
      Offset(w/2, h * 0.95),
      [
        Colors.white.withOpacity(0.85), // 头
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.05), // 尾
        Colors.transparent,
      ],
      const [0.0, 0.25, 0.85, 1.0],
    );

    final glow = Paint()
      ..shader = shader
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 1.0);
    c.drawRRect(r, glow);

    final core = Paint()..color = Colors.white.withOpacity(0.55);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - 1.2) / 2, h * 0.08, 1.2, h * 0.70),
        const Radius.circular(0.9),
      ),
      core,
    );

    final pic = rec.endRecording();
    return pic.toImage(w, h);
  }

  double _hashJitter(_Drop d, int salt) {
    final h = d.worldPos.x.toInt() * 73856093 ^ d.worldPos.y.toInt() * 19349663 ^ salt;
    return ((h & 0xFFFF) / 65535.0);
  }
}

// ===== 内部结构 =====
class _RainPatch {
  final int tx, ty;
  final List<_Drop> drops;
  _RainPatch({required this.tx, required this.ty, required this.drops});
}

class _Drop {
  Vector2 worldPos;
  Vector2 vel;
  double length; // px
  double width;  // px（仅非 atlas 分支用）
  double alpha;  // 0..1
  _Drop({
    required this.worldPos,
    required this.vel,
    required this.length,
    required this.width,
    required this.alpha,
  });
}
