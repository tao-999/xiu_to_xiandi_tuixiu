import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/number_format.dart';

class HpBarWrapper extends PositionComponent {
  final double width;
  final double height;
  final double Function() ratio;
  final int Function()? currentHp;
  final int Function()? maxHp;
  final Color barColor;
  final Color textColor;

  HpBarWrapper({
    required this.ratio,
    this.width = 40,
    this.height = 3,
    this.currentHp,
    this.maxHp,
    this.barColor = Colors.red,         // ✅ 默认红色
    this.textColor = Colors.white,      // ✅ 默认白色
  }) : super(anchor: Anchor.center);

  late final RectangleComponent _bg;
  late final RectangleComponent _fg;
  late final TextComponent _text;

  @override
  Future<void> onLoad() async {
    size = Vector2(width, height);

    _bg = RectangleComponent(
      size: size,
      anchor: Anchor.topLeft,
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );

    _fg = RectangleComponent(
      size: size,
      anchor: Anchor.topLeft,
      paint: Paint()
        ..color = barColor
        ..style = PaintingStyle.fill,
    );

    _text = TextComponent(
      text: '',
      anchor: Anchor.centerLeft,
      position: Vector2(width + 4, height / 2),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black),
          ],
        ),
      ),
    );

    add(_bg);
    add(_fg);
    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _fg.scale.x = ratio().clamp(0.0, 1.0);

    if (currentHp != null) {
      _text.text = formatAnyNumber(currentHp!());
    }
  }
}
