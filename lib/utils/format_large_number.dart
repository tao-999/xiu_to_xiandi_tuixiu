/// 数值单位格式化工具（支持 万、亿、兆、京、垓、秭、穰、沟、涧、正、载、极）
String formatLargeNumber(num value) {
  // 完整单位表，按万进位扩展至 "极"
  const units = [
    '', '万', '亿', '兆', '京', '垓', '秭',
    '穰', '沟', '涧', '正', '载', '极'
  ];

  int unitIndex = 0;
  double val = value.toDouble();

  // 每次除以1万，直到值足够小或单位已达极限
  while (val >= 10000 && unitIndex < units.length - 1) {
    val /= 10000;
    unitIndex++;
  }

  // 如果单位是最小单位（即""），不显示小数
  if (unitIndex == 0) {
    return value.toStringAsFixed(0);
  } else {
    // 抹除末尾多余的0
    String trimmed = val.toStringAsFixed(4).replaceFirst(RegExp(r'\.0+\$'), '').replaceFirst(RegExp(r'(\.\d*?)0+\$'), r'\1');
    return '$trimmed${units[unitIndex]}';
  }
}