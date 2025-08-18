import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/noise_utils.dart';

class FbmTerrainLayer extends PositionComponent {
  final Vector2 Function() getViewSize;
  final double  Function() getViewScale;
  final Vector2 Function() getLogicalOffset;

  // 可选：不传也行（默认 0,0）；传了就能做到任何情况下都绝对无缝
  final Vector2 Function() getWorldBase;
  static Vector2 _zeroBase() => Vector2.zero();

  // ===== 基础 fBm 参数 =====
  double frequency;
  int    octaves;
  double persistence;
  bool   animate;
  final  int seed;

  final bool debugLogUniforms;
  double debugLevel;

  bool   useLodAdaptive;
  double lodNyquist;

  // ===== 海面参数（ABI 保留，但 Shader 已纯色不再使用）=====
  bool   oceanEnable;     // 15
  double seaLevel;        // 16
  double oceanAmp;        // 17
  double oceanSpeed;      // 18
  double oceanChoppy;     // 19
  double sunTheta;        // 20 (弧度)
  double sunStrength;     // 21
  double foamWidth;       // 22
  double foamIntensity;   // 23

  static ui.FragmentProgram? _cachedProgram;
  ui.FragmentShader? _shader;
  final Paint _paint = Paint();
  final Paint _fallback = Paint()..color = const Color(0xFF0B0B0B);

  ui.Image? _perm1, _perm2, _perm3;

  double _t = 0.0;
  double _logTimer = 0.0;

  // ⚡️ 小优化：缓存频率对应的重基周期，频率变化才重算
  double? _cachedFreq;
  double? _cachedRebaseUnit;

  FbmTerrainLayer({
    required this.getViewSize,
    required this.getViewScale,
    required this.getLogicalOffset,
    this.getWorldBase = _zeroBase,
    this.frequency = 0.004,
    this.octaves = 6,
    this.persistence = 0.6,
    this.animate = false,      // 纯色模式下默认 false，省一丢丢 CPU
    this.seed = 1337,
    this.debugLogUniforms = false,
    this.debugLevel = 0.0,
    this.useLodAdaptive = true,
    this.lodNyquist = 0.5,
    // —— 海面默认值（已不影响渲染，但保留 ABI）——
    this.oceanEnable = false,  // ✅ 默认关，避免误用老海浪 Shader 时算重特效
    this.seaLevel = 0.43,
    this.oceanAmp = 0.0,
    this.oceanSpeed = 0.0,
    this.oceanChoppy = 0.0,
    double? sunThetaDegrees,
    this.sunStrength = 0.0,
    this.foamWidth = 0.0,
    this.foamIntensity = 0.0,
    int? priority,
  })  : sunTheta = (sunThetaDegrees != null)
      ? sunThetaDegrees * math.pi / 180.0
      : (40.0 * math.pi / 180.0),
        super(priority: priority ?? -10000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      // ⚠️ 路径保持不变：请把你“纯色版”的 shader 覆盖到同名文件
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
    if (animate) _t += dt;           // 纯色 Shader 未用到 time；留作扩展
    if (debugLogUniforms) _logTimer += dt;
  }

  // 安全的 double 取模（兼容负数）
  double _fmod(double a, double m) {
    if (!a.isFinite || !m.isFinite || m == 0) return 0.0;
    final q = (a / m).floorToDouble();
    return a - q * m;
  }

  @override
  void render(Canvas canvas) {
    final screen = getViewSize();
    final scale  = getViewScale();
    final center = getLogicalOffset();
    final base   = getWorldBase();

    final worldSize    = screen / scale;
    final worldTopLeft = center - worldSize / 2;
    final rect = Rect.fromLTWH(0, 0, screen.x, screen.y);

    final s = _shader;
    if (s == null || _perm1 == null || _perm2 == null || _perm3 == null) {
      canvas.drawRect(rect, _fallback);
      return;
    }

    try {
      // ✅ 与 Shader 一致：基础周期 = 256 / frequency
      final double f = frequency.abs() > 1e-12 ? frequency.abs() : 1e-12;

      // ⚡️频率不变就复用周期
      double rebaseUnit;
      if (_cachedFreq != null && (_cachedFreq! - f).abs() < 1e-12 && _cachedRebaseUnit != null) {
        rebaseUnit = _cachedRebaseUnit!;
      } else {
        rebaseUnit = 256.0 / f;
        _cachedFreq = f;
        _cachedRebaseUnit = rebaseUnit;
      }

      // ✅ Dart 侧先取模，传已取模的 worldBase（重基无缝）
      final double baseX = _fmod(base.x, rebaseUnit);
      final double baseY = _fmod(base.y, rebaseUnit);

      // 0~14：基础参数
      s.setFloat(0,  screen.x);
      s.setFloat(1,  screen.y);
      s.setFloat(2,  worldTopLeft.x);
      s.setFloat(3,  worldTopLeft.y);
      s.setFloat(4,  scale);
      s.setFloat(5,  frequency);
      s.setFloat(6,  animate ? _t : 0.0);     // 纯色版目前未用
      s.setFloat(7,  octaves.clamp(1, 8).toDouble());
      s.setFloat(8,  persistence);
      s.setFloat(9,  seed.toDouble());
      s.setFloat(10, debugLevel);
      s.setFloat(11, useLodAdaptive ? 1.0 : 0.0);
      s.setFloat(12, lodNyquist);
      s.setFloat(13, baseX);
      s.setFloat(14, baseY);

      // 15~23：海面参数（ABI 保留；纯色版 Shader 不读取，但传零成本很低、最稳）
      s.setFloat(15, oceanEnable ? 1.0 : 0.0);
      s.setFloat(16, seaLevel);
      s.setFloat(17, oceanAmp);
      s.setFloat(18, oceanSpeed);
      s.setFloat(19, oceanChoppy);
      s.setFloat(20, sunTheta);
      s.setFloat(21, sunStrength);
      s.setFloat(22, foamWidth);
      s.setFloat(23, foamIntensity);

      s.setImageSampler(0, _perm1!);
      s.setImageSampler(1, _perm2!);
      s.setImageSampler(2, _perm3!);

      _paint.shader = s;
      canvas.drawRect(rect, _paint);

      if (debugLogUniforms && _logTimer >= 1.0) {
        _logTimer = 0.0;
        debugPrint('[FbmTerrainLayer] scale=$scale freq=$frequency oct=$octaves '
            'lod=${useLodAdaptive?1:0} nyq=$lodNyquist base=(${baseX.toStringAsFixed(1)},${baseY.toStringAsFixed(1)}) '
            'dbg=$debugLevel time=${_t.toStringAsFixed(2)}');
      }
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

  // 便捷更新接口（保留；对纯色版无硬性影响）
  void setOcean({
    bool? enable,
    double? seaLevel,
    double? amp,
    double? speed,
    double? choppy,
    double? sunThetaDegrees,
    double? sunStrength,
    double? foamWidth,
    double? foamIntensity,
  }) {
    if (enable != null) oceanEnable = enable;
    if (seaLevel != null) this.seaLevel = seaLevel;
    if (amp != null) oceanAmp = amp;
    if (speed != null) oceanSpeed = speed;
    if (choppy != null) oceanChoppy = choppy;
    if (sunThetaDegrees != null) {
      sunTheta = sunThetaDegrees * math.pi / 180.0;
    }
    if (sunStrength != null) this.sunStrength = sunStrength;
    if (foamWidth != null) this.foamWidth = foamWidth;
    if (foamIntensity != null) this.foamIntensity = foamIntensity;
  }
}
