// 📄 lib/widgets/effects/fbm_terrain_layer.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/noise_utils.dart';

class FbmTerrainLayer extends PositionComponent {
  // === 视图 / 世界 ===
  final Vector2 Function() getViewSize;      // 屏幕像素尺寸
  final double Function() getViewScale;      // px / world
  final Vector2 Function() getLogicalOffset; // 世界相机中心

  // === fBm 参数（与 CPU 保持一致） ===
  double frequency;
  int    octaves;       // 1..8（shader 内部会 clamp 至 8）
  double persistence;   // 0.2..0.9
  bool   animate;
  final int seed;

  /// 控制台打印 uniforms（每秒一次）
  final bool debugLogUniforms;

  /// 0=正常；1=坐标热图；2=perm 检查
  double debugLevel;

  /// 🆕 LOD 自适应：缩得很远时跳过高频 octave
  bool   useLodAdaptive;
  double lodNyquist; // 建议 0.5

  // ---- Shader & 纹理 ----
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
    this.frequency = 0.004,
    this.octaves = 6,
    this.persistence = 0.6,
    this.animate = false,
    this.seed = 1337,
    this.debugLogUniforms = false,
    this.debugLevel = 0.0,
    this.useLodAdaptive = true, // 🆕 默认开启
    this.lodNyquist = 0.5,      // 🆕
    int? priority,
  }) : super(priority: priority ?? -10000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _cachedProgram ??= await ui.FragmentProgram.fromAsset('shaders/fbm_terrain.frag');
      _shader = _cachedProgram!.fragmentShader();

      // 三张与 CPU 完全一致的 perm 纹理（seed, seed+999, seed-999）
      _perm1 = await _buildPermImage(NoiseUtils(seed).perm);
      _perm2 = await _buildPermImage(NoiseUtils(seed + 999).perm);
      _perm3 = await _buildPermImage(NoiseUtils(seed - 999).perm);

      if (debugLogUniforms) {
        debugPrint('[FbmTerrainLayer] ✅ Shader loaded. '
            'seed=$seed freq=$frequency oct=$octaves per=$persistence '
            'lod=${useLodAdaptive ? "on" : "off"} nyq=$lodNyquist');
      }
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
    final screen = getViewSize();   // px
    final scale  = getViewScale();  // px/world
    final center = getLogicalOffset();
    final worldSize    = screen / scale;
    final worldTopLeft = center - worldSize / 2;
    final rect = Rect.fromLTWH(0, 0, screen.x, screen.y);

    final s = _shader;
    if (s == null) {
      canvas.drawRect(rect, _fallback);
      return;
    }
    if (_perm1 == null || _perm2 == null || _perm3 == null) {
      canvas.drawRect(rect, _fallback);
      return;
    }

    if (debugLogUniforms && _logTimer >= 1.0) {
      _logTimer = 0.0;
      debugPrint(
        '[FbmTerrainLayer] uniforms → '
            'uResolution=(${screen.x.toStringAsFixed(1)}, ${screen.y.toStringAsFixed(1)}) '
            'uWorldTopLeft=(${worldTopLeft.x.toStringAsFixed(2)}, ${worldTopLeft.y.toStringAsFixed(2)}) '
            'uScale=${scale.toStringAsFixed(5)} '
            'uFreq=${frequency.toStringAsFixed(8)} '
            'uTime=${(animate ? _t : 0.0).toStringAsFixed(3)} '
            'uOctaves=${octaves.clamp(1, 8)} '
            'uPersistence=${persistence.toStringAsFixed(3)} '
            'seed=$seed debug=$debugLevel '
            'LOD=${useLodAdaptive ? "ON" : "OFF"} nyq=$lodNyquist',
      );
    }

    try {
      // ---- setFloat（严格按 .frag 声明顺序） ----
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
      s.setFloat(11, useLodAdaptive ? 1.0 : 0.0); // 🆕 uLodEnable
      s.setFloat(12, lodNyquist);                 // 🆕 uLodNyquist

      // ---- 绑定采样器（uPerm1/uPerm2/uPerm3） ----
      s.setImageSampler(0, _perm1!);
      s.setImageSampler(1, _perm2!);
      s.setImageSampler(2, _perm3!);

      // ---- 绘制 ----
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

  /// 把 0..255 的 perm 数组烘成 256x1 R 通道纹理（采样时取 .r）
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
