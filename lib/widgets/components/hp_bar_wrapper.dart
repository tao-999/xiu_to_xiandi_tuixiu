import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/number_format.dart';

class HpBarWrapper extends PositionComponent {
  final double width;
  final double height;
  final Color barColor;
  final Color textColor;

  late final RectangleComponent _bg;
  late final RectangleComponent _fg;
  late final TextComponent _text;

  HpBarWrapper({
    this.width = 40,
    this.height = 3,
    this.barColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(anchor: Anchor.center);

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

  /// 🌟外部调用此方法更新血条和文字
  void setHp(int current, int max) {
    final ratio = max == 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    _fg.scale.x = ratio;
    _text.text = formatAnyNumber(current);
  }
}
