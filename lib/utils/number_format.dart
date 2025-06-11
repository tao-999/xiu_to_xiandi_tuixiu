/// 🌟 超大数值格式化工具（支持 num / BigInt，单位：万、亿、兆、京…）
/// 用法：formatAnyNumber(value)
library number_format;

/// 通用单位列表（10^4 为单位基准）
const _units = [
  '', '万', '亿', '兆', '京', '垓', '秭',
  '穰', '沟', '涧', '正', '载', '极'
];

/// 🔢 格式化 num 类型（如 double / int）
String formatLargeNumber(num value) {
  int unitIndex = 0;
  double val = value.toDouble();

  while (val >= 10000 && unitIndex < _units.length - 1) {
    val /= 10000;
    unitIndex++;
  }

  if (unitIndex == 0) {
    return value.toStringAsFixed(0);
  } else {
    String formatted = val.toStringAsFixed(4);
    formatted = formatted.contains('.')
        ? formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : formatted;
    return '$formatted${_units[unitIndex]}';
  }
}

/// 🔢 格式化 BigInt 类型（只保留整数单位）
String formatBigInt(BigInt value) {
  const units = [
    '', '万', '亿', '兆', '京', '垓', '秭',
    '穰', '沟', '涧', '正', '载', '极'
  ];

  BigInt base = BigInt.from(10000);
  int unitIndex = 0;
  BigInt temp = value;

  while (temp >= base && unitIndex < units.length - 1) {
    temp = temp ~/ base;
    unitIndex++;
  }

  // ✅ 计算当前单位下的值（精确小数，使用整数模拟）
  final divisor = BigInt.from(10000).pow(unitIndex);
  final mantissa = value * BigInt.from(10000) ~/ divisor;
  final doubleVal = mantissa.toDouble() / 10000;

  // ✅ 格式化小数位
  String formatted = doubleVal.toStringAsFixed(4);
  formatted = formatted.contains('.')
      ? formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : formatted;

  return '$formatted${units[unitIndex]}';
}

/// 🧠 智能格式化（自动识别 num / BigInt）
String formatAnyNumber(dynamic value) {
  if (value is BigInt) return formatBigInt(value);
  if (value is num) return formatLargeNumber(value);
  return value.toString(); // fallback
}
