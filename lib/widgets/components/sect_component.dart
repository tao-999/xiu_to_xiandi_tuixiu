import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'sect_info.dart';

class SectComponent extends PositionComponent
    with HasGameReference<FlameGame>, CollisionCallbacks {
  final SectInfo info;
  final ui.Image image;
  final double imageSize;
  Vector2 worldPosition;
  final double circleRadius;

  /// 🌟漂移速度（每秒像素）
  Vector2 velocity = Vector2.zero();

  /// 随机漂移方向定时器
  double _directionTimer = 0;

  SectComponent({
    required this.info,
    required this.image,
    required this.imageSize,
    required this.worldPosition,
    required this.circleRadius,
  }) : super(
    size: Vector2.all(circleRadius * 2), // 💥改这里：用圆直径
    anchor: Anchor.center, // 💥锚点中心
  ) {
    _assignRandomVelocity();
  }

  /// 🌟初始化碰撞盒
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      CircleHitbox(
        radius: circleRadius, // 和渲染半径一致
        anchor: Anchor.topLeft,
        collisionType: CollisionType.passive,
      ),
    );
  }

  /// 🌟生成随机方向与速度
  void _assignRandomVelocity() {
    final random = Random();
    final angle = random.nextDouble() * pi * 2;
    final speed = 20.0 + random.nextDouble() * 2.0;
    velocity = Vector2(cos(angle), sin(angle)) * speed;
    _directionTimer = 3.0 + random.nextDouble() * 3.0; // 3~6秒换方向
  }

  /// 🌟停止漂移
  void stopMovement() {
    velocity = Vector2.zero();
  }

  /// 🌟更新物理位置与推开逻辑
  void updatePhysics(List<SectComponent> allSects, double dt, double mapMaxSize) {
    _directionTimer -= dt;
    if (_directionTimer <= 0) {
      _assignRandomVelocity();
    }

    worldPosition += velocity * dt;

    for (final other in allSects) {
      if (identical(this, other)) continue;
      final delta = worldPosition - other.worldPosition;
      final dist = delta.length;
      final minDist = circleRadius * 2.0;
      if (dist < minDist && dist > 0.01) {
        final push = (minDist - dist) * 0.5;
        final dir = delta.normalized();
        worldPosition += dir * push;
      }
    }

    if (worldPosition.x < -mapMaxSize + circleRadius) {
      worldPosition.x = -mapMaxSize + circleRadius;
      velocity.x *= -1;
    }
    if (worldPosition.x > mapMaxSize - circleRadius) {
      worldPosition.x = mapMaxSize - circleRadius;
      velocity.x *= -1;
    }
    if (worldPosition.y < -mapMaxSize + circleRadius) {
      worldPosition.y = -mapMaxSize + circleRadius;
      velocity.y *= -1;
    }
    if (worldPosition.y > mapMaxSize - circleRadius) {
      worldPosition.y = mapMaxSize - circleRadius;
      velocity.y *= -1;
    }
  }

  /// 🌟更新屏幕显示位置
  void updateVisualPosition(Vector2 cameraOffset) {
    position = worldPosition - cameraOffset;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // 🌟发光骚白圈
    final ui.Paint glowPaint = ui.Paint()
      ..color = const ui.Color(0x88FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);
    canvas.drawCircle(
      ui.Offset(size.x / 2, size.y / 2),
      circleRadius,
      glowPaint,
    );

    // 🌟极细白色主线
    final ui.Paint linePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      ui.Offset(size.x / 2, size.y / 2),
      circleRadius,
      linePaint,
    );

    // 🌟宗门图片
    final src = ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = ui.Rect.fromCenter(
      center: ui.Offset(size.x / 2, size.y / 2),
      width: imageSize,
      height: imageSize,
    );
    canvas.drawImageRect(image, src, dst, ui.Paint());

    // 🌟宗门名字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${info.level}级·${info.name}',
        style: TextStyle(
          color: const ui.Color(0xFFFFFFFF),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      ui.Offset(
        (size.x - textPainter.width) / 2,
        dst.top - 24,
      ),
    );
  }
}
