extension BigIntExtensions on BigInt {
  /// ✅ clamp：限制在最小和最大之间
  BigInt clamp(BigInt min, BigInt max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// ✅ 精准格式化为字符串（保留指定位数）
  String formatDigits({int maxLength = 16}) {
    final str = toString();
    return str.length <= maxLength ? str : '${str.substring(0, maxLength)}...';
  }
}
