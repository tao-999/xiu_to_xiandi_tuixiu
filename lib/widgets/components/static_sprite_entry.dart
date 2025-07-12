/// 静态贴图配置
class StaticSpriteEntry {
  final String path;
  final int weight;
  final double? minSize;
  final double? maxSize;
  final int? minCount;
  final int? maxCount;
  final double? tileSize;

  const StaticSpriteEntry(
      this.path,
      this.weight, {
        this.minSize,
        this.maxSize,
        this.minCount,
        this.maxCount,
        this.tileSize,
      });
}
