/// 动态贴图配置（用于动态生成移动组件）
class DynamicSpriteEntry {
  /// 图片路径
  final String path;

  /// 权重（用于随机挑选）
  final int weight;

  /// 最小尺寸
  final double? minSize;

  /// 最大尺寸
  final double? maxSize;

  /// 最少生成数量
  final int? minCount;

  /// 最多生成数量
  final int? maxCount;

  /// 格子尺寸（如果需要覆盖默认tileSize）
  final double? tileSize;

  /// 最小速度
  final double? minSpeed;

  /// 最大速度
  final double? maxSpeed;

  /// 默认是否朝右（true=默认朝右，false=默认朝左）
  final bool defaultFacingRight;

  const DynamicSpriteEntry(
      this.path,
      this.weight, {
        this.minSize,
        this.maxSize,
        this.minCount,
        this.maxCount,
        this.tileSize,
        this.minSpeed,
        this.maxSpeed,
        this.defaultFacingRight = true, // 新增
      });
}
