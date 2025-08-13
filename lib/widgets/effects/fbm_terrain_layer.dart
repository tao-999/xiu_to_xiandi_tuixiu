import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/noise_utils.dart';

class FbmTerrainLayer extends PositionComponent {
  final Vector2 Function() getViewSize;
  final double Function() getViewScale;
  final Vector2 Function() getLogicalOffset;

  // 保留接口以便以后扩展；本版里传入 Vector2.zero()
  final Vector2 Function() getWorldBase;

  double frequency;
  int    octaves;
  double persistence;
  bool   animate;
  final  int seed;

  final bool debugLogUniforms;
  double debugLevel;

  // LOD
  bool   useLodAdaptive;
  double lodNyquist;

  static ui.FragmentProgram? _cachedProgram;
  ui.FragmentShader? _shader;
  final Paint _paint = Paint();
  final Paint _fallback = Paint()..color = const Color(0xFF0B0B0B);

  ui.Image? _perm1, _perm2, _perm3;

  double _t = 0.0;
  double _logTimer = 0.0;

  FbmTerrainLayer({
    required this.getViewSize,
    required this.getViewScale,
    required this.getLogicalOffset,
    required this.getWorldBase,
    this.frequency = 0.004,
    this.octaves = 6,
    this.persistence = 0.6,
    this.animate = false,
    this.seed = 1337,
    this.debugLogUniforms = false,
    this.debugLevel = 0.0,
    this.useLodAdaptive = true,
    this.lodNyquist = 0.5,
    int? priority,
  }) : super(priority: priority ?? -10000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _cachedProgram ??= await ui.FragmentProgram.fromAsset('shaders/fbm_terrain.frag');
      _shader = _cachedProgram!.fragmentShader();

      _perm1 = await _buildPermImage(NoiseUtils(seed).perm);
      _perm2 = await _buildPermImage(NoiseUtils(seed + 999).perm);
      _perm3 = await _buildPermImage(NoiseUtils(seed - 999).perm);
    } catch (e, st) {
      debugPrint('[FbmTerrainLayer] ⚠️ Shader load failed: $e\n$st');
      _shader = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (animate) _t += dt;
    if (debugLogUniforms) _logTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final screen = getViewSize();
    final scale  = getViewScale();
    final center = getLogicalOffset();

    final worldSize    = screen / scale;
    final worldTopLeft = center - worldSize / 2;
    final rect = Rect.fromLTWH(0, 0, screen.x, screen.y);

    final s = _shader;
    if (s == null || _perm1 == null || _perm2 == null || _perm3 == null) {
      canvas.drawRect(rect, _fallback);
      return;
    }

    try {
      s.setFloat(0,  screen.x);
      s.setFloat(1,  screen.y);
      s.setFloat(2,  worldTopLeft.x);
      s.setFloat(3,  worldTopLeft.y);
      s.setFloat(4,  scale);
      s.setFloat(5,  frequency);
      s.setFloat(6,  animate ? _t : 0.0);
      s.setFloat(7,  octaves.clamp(1, 8).toDouble());
      s.setFloat(8,  persistence);
      s.setFloat(9,  seed.toDouble());
      s.setFloat(10, debugLevel);
      s.setFloat(11, useLodAdaptive ? 1.0 : 0.0);
      s.setFloat(12, lodNyquist);

      // ✅ 关键：把 uWorldBase 固定传 0，保证 GPU 与 CPU 完全一致
      s.setFloat(13, 0.0);
      s.setFloat(14, 0.0);

      s.setImageSampler(0, _perm1!);
      s.setImageSampler(1, _perm2!);
      s.setImageSampler(2, _perm3!);

      _paint.shader = s;
      canvas.drawRect(rect, _paint);
    } catch (e, st) {
      debugPrint('[FbmTerrainLayer] set uniforms/samplers failed: $e\n$st');
      canvas.drawRect(rect, _fallback);
    }
  }

  @override
  void onRemove() {
    _perm1?.dispose();
    _perm2?.dispose();
    _perm3?.dispose();
    super.onRemove();
  }

  Future<ui.Image> _buildPermImage(List<int> perm) async {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    for (int i = 0; i < 256; i++) {
      final v = perm[i].clamp(0, 255);
      c.drawRect(
        Rect.fromLTWH(i.toDouble(), 0, 1, 1),
        Paint()..color = Color.fromARGB(0xFF, v, 0, 0),
      );
    }
    final pic = recorder.endRecording();
    return pic.toImage(256, 1);
  }
}
