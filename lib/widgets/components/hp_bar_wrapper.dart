import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HpBarWrapper extends PositionComponent {
  final double width;
  final double height;
  final double Function() ratio;

  HpBarWrapper({
    required this.ratio,
    this.width = 40,   // ✅ 默认宽度改大一点更舒服
    this.height = 3,
  }) : super(anchor: Anchor.center);

  late final RectangleComponent _bg;
  late final RectangleComponent _fg;

  @override
  Future<void> onLoad() async {
    size = Vector2(width, height);

    // 底色
    _bg = RectangleComponent(
      size: size,
      anchor: Anchor.topLeft,
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );

    // 血条
    _fg = RectangleComponent(
      size: size,
      anchor: Anchor.topLeft,
      paint: Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    add(_bg);
    add(_fg);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 只缩放X轴，血条动画丝滑~
    _fg.scale.x = ratio().clamp(0.0, 1.0);
  }
}
