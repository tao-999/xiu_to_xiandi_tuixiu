class StaticSpriteEntry {
  final String path;
  final int weight;

  final String? type;
  final double? fixedSize;
  final int? minCount;
  final int? maxCount;

  /// 🆕 最终绘制层级（如果设置，将覆盖自动计算的 priority）
  final int? priority;

  const StaticSpriteEntry(
      this.path,
      this.weight, {
        this.type,
        this.fixedSize,
        this.minCount,
        this.maxCount,
        this.priority, // ✅ 新增
      });

  StaticSpriteEntry copyWith({
    String? path,
    int? weight,
    String? type,
    double? fixedSize,
    int? minCount,
    int? maxCount,
    int? priority, // ✅ 新增
  }) {
    return StaticSpriteEntry(
      path ?? this.path,
      weight ?? this.weight,
      type: type ?? this.type,
      fixedSize: fixedSize ?? this.fixedSize,
      minCount: minCount ?? this.minCount,
      maxCount: maxCount ?? this.maxCount,
      priority: priority ?? this.priority,
    );
  }
}
