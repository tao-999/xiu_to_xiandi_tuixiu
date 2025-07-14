class StaticSpriteEntry {
  final String path;
  final int weight;
  final double? fixedSize;
  final int? minCount;
  final int? maxCount;

  const StaticSpriteEntry(
      this.path,
      this.weight, {
        this.fixedSize,
        this.minCount,
        this.maxCount,
      });
}
