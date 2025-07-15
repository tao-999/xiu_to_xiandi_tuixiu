import 'package:flame/components.dart';
import 'dart:ui';

/// 动态贴图配置（用于动态生成移动组件）
class DynamicSpriteEntry {
  /// 图片路径
  final String path;

  /// 权重（用于随机挑选）
  final int weight;

  /// 最小尺寸（⚠️当 desiredWidth 为 null 时启用）
  final double? minSize;

  /// 最大尺寸（⚠️当 desiredWidth 为 null 时启用）
  final double? maxSize;

  /// 最少生成数量
  final int? minCount;

  /// 最多生成数量
  final int? maxCount;

  /// 格子尺寸（如果需要覆盖默认 tileSize）
  final double? tileSize;

  /// 最小速度
  final double? minSpeed;

  /// 最大速度
  final double? maxSpeed;

  /// 默认是否朝右（true=默认朝右，false=默认朝左）
  final bool defaultFacingRight;

  /// 基准尺寸（可选，不需要时留 null）
  final Vector2? baseSize;

  /// 如果指定，将强制缩放到此宽度（优先级最高）
  final double? desiredWidth;

  /// 🟢 常驻文字内容
  final String? labelText;

  /// 🟢 文字大小
  final double? labelFontSize;

  /// 🟢 文字颜色
  final Color? labelColor;

  /// 🟢 最小移动距离
  final double? minDistance;

  /// 🟢 最大移动距离
  final double? maxDistance;

  /// 🟢 碰撞时的台词
  final List<String>? collisionTexts;

  /// 是否生成随机名字
  final bool generateRandomLabel;

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
        this.defaultFacingRight = true,
        this.baseSize,
        this.desiredWidth, // 🌟新增
        this.labelText,
        this.labelFontSize,
        this.labelColor,
        this.minDistance,
        this.maxDistance,
        this.collisionTexts,
        this.generateRandomLabel = false,
      });
}
