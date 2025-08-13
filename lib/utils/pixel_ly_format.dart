// 📦 lib/utils/pixel_ly_format.dart
// 规则：< 1 光年 → 米/万米/亿米/兆米…；≥ 1 光年 → 光年/万光年/亿光年/兆光年…
// 比例：64 像素 = 1 米（写死）

import 'package:flame/components.dart';

// 固定比例
const double kPxPerMeter = 24.0;

// 1 光年（米）
const double _M_PER_LY = 9.4607304725808e15;

// 中文 10^4 阶梯
const List<String> _CN_UNITS = [
  '', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极',
  '恒河沙', '阿僧祇', '那由他', '不可思议', '无量大数',
];

double _safe(num x, [double fb = 0.0]) {
  final d = x.toDouble();
  return d.isFinite ? d : fb;
}

String _trimZeros(String s) =>
    s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// 像素 → 米（64px = 1m）
double pixelsToMeters(num pixels) => _safe(pixels) / kPxPerMeter;

/// 米 → 光年
double metersToLy(num meters) => _safe(meters) / _M_PER_LY;

/// 米系（用于 < 1 光年）：
/// - < 10000 m  → “XXXX 米”
/// - ≥ 10000 m  → “X[.xx] 万/亿/兆…米”
String formatMetersWanCN(
    num meters, {
      int fractionDigits = 4,
    }) {
  final m = _safe(meters).abs(); // 距离非负
  if (!m.isFinite) return '∞ 米';
  if (m < 10000) return '${m.round()} 米';

  double val = m;
  int idx = 0;
  while (val >= 10000 && idx < _CN_UNITS.length - 1) {
    val /= 10000.0;
    idx++;
  }
  String s = val.toStringAsFixed(fractionDigits);
  s = _trimZeros(s);
  return '$s${_CN_UNITS[idx]}米';
}

/// 光年系（用于 ≥ 1 光年）：
/// - [1, 10000) ly → “X[.xx] 光年”
/// - ≥ 10000 ly     → “X[.xx] 万/亿/兆…光年”
String formatGuangNianCN(
    num ly, {
      int fractionDigits = 4,
    }) {
  final v = _safe(ly).abs(); // 距离非负
  if (!v.isFinite) return '∞ 光年';

  double val = v;
  int idx = 0;
  while (val >= 10000 && idx < _CN_UNITS.length - 1) {
    val /= 10000.0;
    idx++;
  }
  String s = val.toStringAsFixed(fractionDigits);
  s = _trimZeros(s);
  return '$s${_CN_UNITS[idx]}光年';
}

/// 严格规则：<1 光年用“米系”，≥1 光年用“光年系”（全中文单位）
String formatPixelsStrictCN(
    num pixels, {
      int meterDigits = 4,
      int lyDigits = 4,
    }) {
  final meters = pixelsToMeters(pixels);
  final ly = metersToLy(meters);
  if (ly < 1.0) {
    return formatMetersWanCN(meters, fractionDigits: meterDigits);
  } else {
    return formatGuangNianCN(ly, fractionDigits: lyDigits);
  }
}

/// 距离原点（worldBase + local，以像素为坐标）→ 严格中文格式
String formatDistanceFromOriginStrictCN({
  required Vector2 worldBase,
  required Vector2 localPos,
  int meterDigits = 4,
  int lyDigits = 4,
}) {
  final global = worldBase + localPos; // 像素
  final distPx = global.length;
  return formatPixelsStrictCN(distPx, meterDigits: meterDigits, lyDigits: lyDigits);
}
