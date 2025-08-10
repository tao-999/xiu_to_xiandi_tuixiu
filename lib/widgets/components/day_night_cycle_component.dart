import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

/// 昼夜阶段
enum DayNightPhase { night, sunrise, day, sunset }

/// 配置（跟之前一致，别动）
class DayNightConfig {
  final int immortalSecondsPerDay;    // 修真世界“1天”=多少真实秒（外部传入）
  final double sunriseStart;          // [0,1)
  final double sunriseEnd;            // [0,1)
  final double sunsetStart;           // [0,1)
  final double sunsetEnd;             // [0,1)
  final double nightBrightness;       // 0~1
  final double dayBrightness;         // 0~1
  final double twilightTintStrength;  // 暮/晓暖色强度 0~1
  final double nightBlueStrength;     // 夜蓝强度 0~1

  const DayNightConfig({
    required this.immortalSecondsPerDay,
    this.sunriseStart = 0.20,
    this.sunriseEnd   = 0.26,
    this.sunsetStart  = 0.75,
    this.sunsetEnd    = 0.82,
    this.nightBrightness = 0.18,
    this.dayBrightness   = 1.0,
    this.twilightTintStrength = 0.35,
    this.nightBlueStrength    = 0.30,
  });
}

/// 外部可读快照（目标值）
class DayNightSnapshot {
  final double dayProgress01;   // 当天进度 [0,1)
  final double brightness01;    // 目标环境亮度 [0,1]
  final DayNightPhase phase;    // 目标阶段
  final Color overlayColor;     // 目标叠加色
  final double overlayAlpha01;  // 目标叠加透明度 0~1
  const DayNightSnapshot({
    this.dayProgress01 = 0,
    this.brightness01 = 1,
    this.phase = DayNightPhase.day,
    this.overlayColor = const Color(0x00000000),
    this.overlayAlpha01 = 0,
  });
}

/// 颜色+透明度（内部用）
class _Overlay {
  final Color color;
  final double alpha;
  const _Overlay(this.color, this.alpha);
}

/// ✅ 纯 Component（Flame 1.29 OK）
/// 现在带：
/// - 可视化“指数平滑”过渡（不闪）
/// - 阶段判定“迟滞”窗口（不抖）
class DayNightCycleComponent extends Component {
  final DayNightConfig config;

  /// 从地图传入：屏幕模式 -> (0,0) / size；世界模式 -> (logicalOffset - size/2) / size
  final Vector2 Function() getVisibleTopLeft;
  final Vector2 Function() getViewSize;

  final void Function(DayNightPhase phase)? onPhaseChanged;
  final int? createdAtSecOverride; // 可选：直接指定玩家创建时间（秒）

  /// —— 过渡参数 —— ///
  /// 可视化平滑时间常数（秒）：越大越丝滑
  final double visualSmoothSec;
  /// 阶段判定迟滞（按修真日比例 0~1），避免在阈值附近来回抖动
  final double phaseHysteresis;

  DayNightSnapshot _snapshot = const DayNightSnapshot(); // 目标
  DayNightSnapshot get snapshot => _snapshot;

  // 可视化用的“显示值”（从目标值平滑过去）
  double _vBrightness = 1.0;
  double _vOverlayAlpha = 0.0;
  Color _vOverlayColor = const Color(0x00000000);

  int _createdAtSec = 0;
  DayNightPhase _lastPhase = DayNightPhase.day;
  bool _initializedVisual = false;

  DayNightCycleComponent({
    required this.config,
    required this.getVisibleTopLeft,
    required this.getViewSize,
    this.onPhaseChanged,
    this.createdAtSecOverride,
    this.visualSmoothSec = 0.6,   // 🌊 默认 0.6s 丝滑过渡
    this.phaseHysteresis = 0.01,  // 🧷 阶段迟滞（1% 修真日）
    int? priority,
  }) {
    this.priority = (priority ?? 99999);
  }

  @override
  Future<void> onLoad() async {
    if (createdAtSecOverride != null) {
      _createdAtSec = createdAtSecOverride!;
    } else {
      final player = await PlayerStorage.getPlayer();
      final created = player?.createdAt;
      if (created is int) {
        _createdAtSec = created > 1000000000000 ? (created ~/ 1000) : created;
      } else {
        _createdAtSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
    }
    // 立刻采样一次，初始化显示值，避免第一帧闪变
    _sampleAndInitVisual();
  }

  void _sampleAndInitVisual() {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = math.max(0, nowSec - _createdAtSec);
    final len = config.immortalSecondsPerDay;
    final daySec = diff % len;
    final p = daySec / len;

    final phase = _phaseOfWithHysteresis(p, _lastPhase, phaseHysteresis);
    final bright = _evalBrightness(p, phase);
    final ov = _evalOverlay(p, phase);

    _lastPhase = phase;
    _snapshot = DayNightSnapshot(
      dayProgress01: p,
      brightness01: bright,
      phase: phase,
      overlayColor: ov.color,
      overlayAlpha01: ov.alpha,
    );

    // 显示值 = 目标值（首帧不闪）
    _vBrightness = bright;
    _vOverlayAlpha = ov.alpha;
    _vOverlayColor = ov.color;
    _initializedVisual = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_createdAtSec == 0) return;

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = math.max(0, nowSec - _createdAtSec);
    final len = config.immortalSecondsPerDay;
    final daySec = diff % len;
    final p = daySec / len; // [0,1)

    // —— 目标值（硬指标）——
    final phase = _phaseOfWithHysteresis(p, _lastPhase, phaseHysteresis);
    final brightTarget = _evalBrightness(p, phase);
    final ovTarget = _evalOverlay(p, phase);

    // 阶段变化回调（只在稳定切换时触发）
    if (phase != _lastPhase && onPhaseChanged != null) {
      onPhaseChanged!(phase);
    }
    _lastPhase = phase;

    _snapshot = DayNightSnapshot(
      dayProgress01: p,
      brightness01: brightTarget,
      phase: phase,
      overlayColor: ovTarget.color,
      overlayAlpha01: ovTarget.alpha,
    );

    // —— 可视化平滑（软过渡）——
    if (!_initializedVisual) {
      _sampleAndInitVisual();
      return;
    }
    final a = _expSmoothingFactor(dt, visualSmoothSec); // 帧率无关的 EMA 系数
    _vBrightness = _vBrightness + (brightTarget - _vBrightness) * a;
    _vOverlayAlpha = _vOverlayAlpha + (ovTarget.alpha - _vOverlayAlpha) * a;
    _vOverlayColor = _smoothColor(_vOverlayColor, ovTarget.color, a);
  }

  @override
  void render(Canvas canvas) {
    final tl = getVisibleTopLeft();
    final vs = getViewSize();
    final w = vs.x, h = vs.y;
    if (w <= 0 || h <= 0) return;

    // 1) 暗度遮罩（平滑后的值）
    final dark = (1.0 - _vBrightness).clamp(0.0, 1.0);
    if (dark > 0.001) {
      final paint = Paint()
        ..color = Color.fromARGB((dark * 255).toInt(), 0, 0, 0)
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(Rect.fromLTWH(tl.x, tl.y, w, h), paint);
    }

    // 2) 色调渐变（平滑后的颜色与透明度）
    if (_vOverlayAlpha > 0.001) {
      final shader = Gradient.linear(
        Offset(tl.x, tl.y),
        Offset(tl.x, tl.y + h),
        <Color>[
          _vOverlayColor.withOpacity(_vOverlayAlpha * 0.9),
          _vOverlayColor.withOpacity(_vOverlayAlpha * 0.4),
          _vOverlayColor.withOpacity(0.0),
        ],
        const <double>[0.0, 0.35, 1.0],
      );
      final paint = Paint()
        ..shader = shader
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(Rect.fromLTWH(tl.x, tl.y, w, h), paint);
    }
  }

  // —— 逻辑 —— //
  DayNightPhase _phaseOfWithHysteresis(
      double t,
      DayNightPhase last,
      double hys,
      ) {
    final c = config;
    // 扩展区间：进入需要 +hys，退出需要 -hys，避免临界来回抖
    if (last == DayNightPhase.night) {
      if (t >= c.sunriseStart + hys) return (t < c.sunriseEnd) ? DayNightPhase.sunrise : DayNightPhase.day;
      return DayNightPhase.night;
    }
    if (last == DayNightPhase.sunrise) {
      if (t < c.sunriseStart - hys) return DayNightPhase.night;
      if (t >= c.sunriseEnd + hys)  return (t < c.sunsetStart) ? DayNightPhase.day : DayNightPhase.sunset;
      return DayNightPhase.sunrise;
    }
    if (last == DayNightPhase.day) {
      if (t >= c.sunsetStart + hys) return (t < c.sunsetEnd) ? DayNightPhase.sunset : DayNightPhase.night;
      if (t < c.sunriseEnd - hys)   return (t < c.sunriseStart) ? DayNightPhase.night : DayNightPhase.sunrise;
      return DayNightPhase.day;
    }
    // last == sunset
    if (t < c.sunsetStart - hys) {
      return (t < c.sunriseEnd) ? (t < c.sunriseStart ? DayNightPhase.night : DayNightPhase.sunrise)
          : DayNightPhase.day;
    }
    if (t >= c.sunsetEnd + hys) return DayNightPhase.night;
    return DayNightPhase.sunset;
  }

  double _evalBrightness(double t, DayNightPhase p) {
    final c = config;
    switch (p) {
      case DayNightPhase.night:
        return c.nightBrightness;
      case DayNightPhase.day:
        return c.dayBrightness;
      case DayNightPhase.sunrise: {
        final k = _invLerp(c.sunriseStart, c.sunriseEnd, t);
        return _smooth(c.nightBrightness, c.dayBrightness, k);
      }
      case DayNightPhase.sunset: {
        final k = _invLerp(c.sunsetStart, c.sunsetEnd, t);
        return _smooth(c.dayBrightness, c.nightBrightness, k);
      }
    }
  }

  _Overlay _evalOverlay(double t, DayNightPhase p) {
    final c = config;
    if (p == DayNightPhase.night) {
      return _Overlay(const Color(0xFF1A2B5A), c.nightBlueStrength); // 夜蓝
    }
    if (p == DayNightPhase.sunrise) {
      final k = _invLerp(c.sunriseStart, c.sunriseEnd, t);
      return _Overlay(const Color(0xFFFF9A42), c.twilightTintStrength * _easeInOut(k)); // 曙光暖
    }
    if (p == DayNightPhase.sunset) {
      final k = _invLerp(c.sunsetStart, c.sunsetEnd, t);
      return _Overlay(const Color(0xFFFF7A2A), c.twilightTintStrength * _easeInOut(1 - k)); // 暮光暖
    }
    return const _Overlay(Color(0x00000000), 0.0);
  }

  // —— 平滑工具 —— //
  double _expSmoothingFactor(double dt, double tau) {
    if (tau <= 0) return 1.0;                  // 直接跟随（无平滑）
    final a = 1.0 - math.exp(-dt / tau);       // 帧率无关 EMA
    return a < 0 ? 0 : (a > 1 ? 1 : a);
  }
  Color _smoothColor(Color cur, Color target, double a) {
    final r = (cur.red   + (target.red   - cur.red)   * a).round();
    final g = (cur.green + (target.green - cur.green) * a).round();
    final b = (cur.blue  + (target.blue  - cur.blue)  * a).round();
    final aa = (cur.alpha + (target.alpha - cur.alpha) * a).round();
    return Color.fromARGB(aa, r, g, b);
  }

  // —— 小工具 —— //
  double _invLerp(double a, double b, double x) {
    final d = b - a;
    if (d == 0) return 0;
    var k = (x - a) / d;
    if (k < 0) k = 0;
    if (k > 1) k = 1;
    return k;
  }
  double _smooth(double a, double b, double k) {
    final s = _easeInOut(k);
    return a + (b - a) * s;
  }
  double _easeInOut(double x) => x * x * (3 - 2 * x);
}
