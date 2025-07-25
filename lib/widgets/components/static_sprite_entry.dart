class StaticSpriteEntry {
  final String path;
  final int weight;

  final String? type; // ✅ 新增：业务类型字段（如 tree, rock, statue）

  final double? fixedSize;
  final int? minCount;
  final int? maxCount;

  const StaticSpriteEntry(
      this.path,
      this.weight, {
        this.type, // ✅ 支持传 type
        this.fixedSize,
        this.minCount,
        this.maxCount,
      });
}
