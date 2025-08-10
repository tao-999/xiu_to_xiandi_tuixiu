// 📦 lib/widgets/effects/vfx_world_season_filter_layer.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, Canvas; // 只要颜色名
import 'package:xiu_to_xiandi_tuixiu/utils/xianji_calendar.dart';

/// 四季预设
class SeasonFilterPreset {
  final ui.Color topColor;     // 顶部色（天光/雾气）
  final ui.Color bottomColor;  // 底部色
  final double alpha;          // 滤镜整体强度 0~1
  final ui.BlendMode blend;    // multiply/screen/overlay/modulate
  final double luminance;      // 亮度乘子 0~1（<1 变暗）
  final double vignette;       // 暗角强度 0~1

  const SeasonFilterPreset({
    required this.topColor,
    required this.bottomColor,
    this.alpha = 0.25,
    this.blend = ui.BlendMode.multiply,
    this.luminance = 1.0,
    this.vignette = 0.0,
  });
}

/// 四季滤镜（视口覆盖，纯 Component）
class WorldSeasonFilterLayer extends Component {
  // 可视区域（屏幕模式 -> (0,0)/size；世界模式 -> (logicalOffset-size/2)/size）
  final Vector2 Function() getVisibleTopLeft;
  final Vector2 Function() getViewSize;

  // 季节 → 预设
  final SeasonFilterPreset spring;
  final SeasonFilterPreset summer;
  final SeasonFilterPreset autumn;
  final SeasonFilterPreset winter;

  // 时序 & 过渡
  final double seasonPollIntervalSec; // 轮询季节间隔（真实秒）
  final double fadeSmoothSec;         // EMA 时间常数（秒），越大越柔
  final bool   enable;                // 总开关

  // 内部状态（目标/显示值）
  SeasonFilterPreset _target;
  ui.Color _vTop = const ui.Color(0x00000000);
  ui.Color _vBot = const ui.Color(0x00000000);
  double _vAlpha = 0.0;
  double _vLum = 1.0;
  double _vVig = 0.0;
  ui.BlendMode _vBlend = ui.BlendMode.multiply;

  double _accPoll = 1e9; // 首帧强制采样
  bool _inited = false;

  WorldSeasonFilterLayer({
    required this.getVisibleTopLeft,
    required this.getViewSize,
    SeasonFilterPreset? spring,
    SeasonFilterPreset? summer,
    SeasonFilterPreset? autumn,
    SeasonFilterPreset? winter,
    this.seasonPollIntervalSec = 3.0,
    this.fadeSmoothSec = 0.8,
    this.enable = true,
    int? priority,
  })  : spring = spring ??
      const SeasonFilterPreset(
        topColor: ui.Color(0xAA9EE6B8),  // 春：嫩绿
        bottomColor: ui.Color(0x668FD69B),
        alpha: 0.18,
        blend: ui.BlendMode.overlay,
        luminance: 1.0,
        vignette: 0.04,
      ),
        summer = summer ??
            const SeasonFilterPreset(
              topColor: ui.Color(0x88FFE082),  // 夏：金暖
              bottomColor: ui.Color(0x66FFCA28),
              alpha: 0.16,
              blend: ui.BlendMode.screen,
              luminance: 1.0,
              vignette: 0.02,
            ),
        autumn = autumn ??
            const SeasonFilterPreset(
              topColor: ui.Color(0x88FFB74D),  // 秋：橙褐
              bottomColor: ui.Color(0x66FF7043),
              alpha: 0.22,
              blend: ui.BlendMode.multiply,
              luminance: 0.96,
              vignette: 0.10,
            ),
        winter = winter ??
            const SeasonFilterPreset(
              topColor: ui.Color(0x8890CAF9),  // 冬：冷蓝
              bottomColor: ui.Color(0x66E3F2FD),
              alpha: 0.20,
              blend: ui.BlendMode.multiply,
              luminance: 0.92,
              vignette: 0.06,
            ),
        _target = winter ?? const SeasonFilterPreset(
          topColor: ui.Color(0x8890CAF9),
          bottomColor: ui.Color(0x66E3F2FD),
        ) {
    this.priority = priority ?? 1200; // 盖在大多数前景之上
  }

  @override
  Future<void> onLoad() async {
    await _sampleSeason(force: true);
    _applyTargetImmediate(); // 首帧不闪
    _inited = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!enable) return;

    // 季节轮询
    _accPoll += dt;
    if (_accPoll >= seasonPollIntervalSec) {
      _accPoll = 0;
      _sampleSeason(); // 异步
    }

    // 指数平滑（帧率无关）
    final a = fadeSmoothSec <= 0 ? 1.0 : (1.0 - exp(-dt / fadeSmoothSec));
    _vTop   = _lerpColor(_vTop, _target.topColor, a);
    _vBot   = _lerpColor(_vBot, _target.bottomColor, a);
    _vAlpha = _vAlpha + (_target.alpha     - _vAlpha) * a;
    _vLum   = _vLum   + (_target.luminance - _vLum  ) * a;
    _vVig   = _vVig   + (_target.vignette  - _vVig  ) * a;
    _vBlend = _target.blend; // 混合模式直接切
  }

  @override
  void render(Canvas canvas) {
    if (!enable && _vAlpha <= 0 && (_vLum - 1.0).abs() < 1e-4 && _vVig <= 0) return;

    final tl = getVisibleTopLeft();
    final vs = getViewSize();
    final w = vs.x, h = vs.y;
    if (w <= 0 || h <= 0) return;

    final rect = ui.Rect.fromLTWH(tl.x, tl.y, w, h);

    // 1) 亮度修正（灰色调制）
    if (_vLum < 0.999) {
      final k = _vLum.clamp(0.0, 1.0);
      final paintLum = ui.Paint()
        ..color = ui.Color.fromARGB(255, (255 * k).round(), (255 * k).round(), (255 * k).round())
        ..blendMode = ui.BlendMode.modulate;
      canvas.drawRect(rect, paintLum);
    }

    // 2) 渐变色调叠加（顶部→底部）
    if (_vAlpha > 0) {
      final shader = ui.Gradient.linear(
        ui.Offset(tl.x, tl.y),
        ui.Offset(tl.x, tl.y + h),
        [
          _vTop.withOpacity(_vAlpha),
          _vBot.withOpacity(_vAlpha * 0.85),
        ],
        const [0.0, 1.0],
      );
      final paintTint = ui.Paint()
        ..shader = shader
        ..blendMode = _vBlend;
      canvas.drawRect(rect, paintTint);
    }

    // 3) 暗角（可选）
    if (_vVig > 0) {
      final cx = tl.x + w / 2, cy = tl.y + h / 2;
      final rad = sqrt(w * w + h * h) * 0.55;
      final shader = ui.Gradient.radial(
        ui.Offset(cx, cy),
        rad,
        [
          const ui.Color(0x00000000),
          Colors.black.withOpacity(0.85 * _vVig),
        ],
        const [0.72, 1.0],
      );
      final paintVig = ui.Paint()
        ..shader = shader
        ..blendMode = ui.BlendMode.srcOver;
      canvas.drawRect(rect, paintVig);
    }
  }

  // —— 季节采样 —— //
  Future<void> _sampleSeason({bool force = false}) async {
    if (!force && !enable) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final s = await XianjiCalendar.seasonFromTimestamp(now);
    switch (s) {
      case '春季': _target = spring; break;
      case '夏季': _target = summer; break;
      case '秋季': _target = autumn; break;
      case '冬季': _target = winter; break;
      default:     _target = spring; break;
    }
    if (!_inited) _applyTargetImmediate();
  }

  void _applyTargetImmediate() {
    _vTop   = _target.topColor;
    _vBot   = _target.bottomColor;
    _vAlpha = _target.alpha;
    _vLum   = _target.luminance;
    _vVig   = _target.vignette;
    _vBlend = _target.blend;
  }

  // —— 工具 —— //
  static ui.Color _lerpColor(ui.Color a, ui.Color b, double t) {
    final ti = 1 - t;
    return ui.Color.fromARGB(
      (a.alpha * ti + b.alpha * t).round(),
      (a.red   * ti + b.red   * t).round(),
      (a.green * ti + b.green * t).round(),
      (a.blue  * ti + b.blue  * t).round(),
    );
  }
}
