import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class SectBuildingComponent extends PositionComponent
    with GestureHitboxes {
  final String buildingName;
  final ui.Image image;
  final double imageSize;
  Vector2 worldPosition; // ✅ 必须为可变
  final double circleRadius;

  final void Function(SectBuildingComponent)? onTap;

  SectBuildingComponent({
    required this.buildingName,
    required this.image,
    required this.imageSize,
    required this.worldPosition,
    required this.circleRadius,
    this.onTap,
    super.priority = 10,
  }) : super(
    position: worldPosition.clone(),
    size: Vector2.all(circleRadius * 2),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ 添加圆形碰撞区域
    add(
      CircleHitbox(
        radius: circleRadius,
        anchor: Anchor.topLeft,
        collisionType: CollisionType.passive,
      ),
    );
  }

  /// ✅ 外部刷新地图视觉位置（基于相机）
  void updateVisualPosition(Vector2 cameraOffset) {
    position = worldPosition - cameraOffset;
  }

  /// ✅ 外部点击触发
  void handleTapExternally() {
    onTap?.call(this);
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // ✨发光边圈
    final glowPaint = ui.Paint()
      ..color = const ui.Color(0x88FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      circleRadius,
      glowPaint,
    );

    // ✨白边实线圈
    final linePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      circleRadius,
      linePaint,
    );

    // ✨建筑贴图
    final src = ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = ui.Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: imageSize,
      height: imageSize,
    );

    canvas.drawImageRect(image, src, dst, ui.Paint());

    // ✨建筑名字
    final textPainter = TextPainter(
      text: TextSpan(
        text: buildingName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, dst.top - 8),
    );
  }
}
