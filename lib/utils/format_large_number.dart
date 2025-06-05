/// 数值单位格式化工具（支持 万、亿、兆、京、垓、秭、穰、沟、涧、正、载、极）
String formatLargeNumber(num value) {
  const units = [
    '', '万', '亿', '兆', '京', '垓', '秭',
    '穰', '沟', '涧', '正', '载', '极'
  ];

  int unitIndex = 0;
  double val = value.toDouble();

  while (val >= 10000 && unitIndex < units.length - 1) {
    val /= 10000;
    unitIndex++;
  }

  if (unitIndex == 0) {
    return value.toStringAsFixed(0);
  } else {
    // 精准保留最多4位小数，去除多余0
    String formatted = val.toStringAsFixed(4);
    formatted = formatted.contains('.') ? formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : formatted;
    return '$formatted${units[unitIndex]}';
  }
}
