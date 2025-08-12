// 📂 lib/widgets/effects/vfx_world_rain_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 解耦版雨层：不依赖 InfiniteGrid；通过 getViewSize/getLogicalOffset 获取视口与相机中心。
/// 用法：
/// host.add(WorldRainLayer(
///   getViewSize: () => size,
///   getLogicalOffset: () => logicalOffset,
///   intensity: 0.6,
///   wind: Vector2(-120, 520),
/// )..priority = 1150);
class WorldRainLayer extends Component {
  // —— 外部注入 —— //
  final Vector2 Function() getViewSize;
  final Vector2 Function() getLogicalOffset;

  // —— 可调口味 —— //
  final double tileSize;
  final double keepFactor;
  final double tilesFps;
  final double intensity;
  final Vector2 wind;
  final int    updateSlices;
  final bool   clipToView;

  // 批渲染纹理（细长雨丝）
  final bool useAtlas;
  final int atlasW;
  final int atlasH;

  // —— 内部 —— //
  final Map<String, _RainPatch> _patches = {};
  double _t = 0;
  double _accTiles = 0;
  int _sliceCursor = 0;
  ui.Image? _streakImg;

  WorldRainLayer({
    required this.getViewSize,
    required this.getLogicalOffset,
    this.tileSize = 256.0,
    this.keepFactor = 1.0,
    this.tilesFps = 12.0,
    this.intensity = 0.6,
    Vector2? wind,
    this.updateSlices = 2,
    this.clipToView = true,
    this.useAtlas = true,
    this.atlasW = 8,
    this.atlasH = 64,
  }) : wind = wind ?? Vector2(-80, 520);

  @override
  Future<void> onLoad() async {
    _streakImg = await _makeStreak(atlasW, atlasH);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    final cam = getLogicalOffset();
    final view = getViewSize();
    final keep = _keepRect(cam, view);

    // —— 1) 生成/卸载（节流） —— //
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

          final r = Random(0x51F15EED ^ (tx*92821) ^ (ty*53987));
          final base = 42;
          final areaK = (tileSize * tileSize) / (128.0 * 128.0);
          final count = max(8, (base * areaK * (0.35 + 1.10 * intensity)).round());

          final rect = _tileRect(tx, ty);
          final drops = <_Drop>[];
          for (int i = 0; i < count; i++) {
            final len   = _randRange(r, 22.0, 60.0) * (0.8 + 1.2 * intensity);
            final speed = _randRange(r, 520.0, 980.0) * (0.75 + 0.8 * intensity);
            final alpha = _randRange(r, 0.06, 0.18) * (0.7 + 0.8 * intensity);
            final width = _randRange(r, 0.6, 1.2);

            final p = Vector2(
              rect.left + r.nextDouble() * rect.width,
              rect.top  + r.nextDouble() * rect.height,
            );
            final v = Vector2(0, speed) + wind;

            drops.add(_Drop(worldPos: p, vel: v, length: len, width: width, alpha: alpha));
          }
          _patches[key] = _RainPatch(tx: tx, ty: ty, drops: drops);
        }
      }

      final toRemove = <String>[];
      _patches.forEach((k, p) {
        final rect = _tileRect(p.tx, p.ty);
        if (!rect.overlaps(keep)) toRemove.add(k);
      });
      for (final k in toRemove) {
        _patches.remove(k);
      }
    }

    // —— 2) 更新（分帧） —— //
    final slices = updateSlices <= 1 ? 1 : updateSlices;
    final sliceIdx = _sliceCursor;

    _patches.forEach((_, patch) {
      int idx = 0;
      for (final d in patch.drops) {
        if (slices > 1 && (idx++ % slices) != sliceIdx) continue;

        d.worldPos += d.vel * dt;

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

    if (clipToView) {
      final v = getViewSize();
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, v.x, v.y));
    }

    final cam = getLogicalOffset();

    if (useAtlas && _streakImg != null) {
      final img = _streakImg!;
      final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final paint = Paint()..filterQuality = FilterQuality.high;

      final transforms = <ui.RSTransform>[];
      final rects = <ui.Rect>[];
      final colors = <Color>[];

      _patches.forEach((_, patch) {
        for (final d in patch.drops) {
          final local = d.worldPos - cam;
          final ang = atan2(d.vel.y, d.vel.x) - pi/2;
          final scale = (d.length / src.height).clamp(0.4, 3.0);

          transforms.add(ui.RSTransform.fromComponents(
            rotation: ang,
            scale: scale,
            anchorX: src.width / 2, anchorY: src.height * 0.8,
            translateX: local.x, translateY: local.y,
          ));
          rects.add(src);
          colors.add(Colors.white.withOpacity(d.alpha));
        }
      });

      if (transforms.isNotEmpty) {
        canvas.drawAtlas(img, transforms, rects, colors, BlendMode.plus, null, paint);
      }
    } else {
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

  Future<ui.Image> _makeStreak(int w, int h) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH((w - 2) / 2, h * 0.05, 2.0, h * 0.90),
      const Radius.circular(1.2),
    );

    final shader = ui.Gradient.linear(
      Offset(w/2, h * 0.05),
      Offset(w/2, h * 0.95),
      [
        Colors.white.withOpacity(0.85),
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.05),
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
