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

  late final TextComponent _hpText;
  late final TextComponent _atkText;
  late final TextComponent _defText;

  // ✅ 用 topLeft，和内部孩子（全是 topLeft）坐标系一致
  HpBarWrapper({
    this.width = 40,
    this.height = 3,
    this.barColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(anchor: Anchor.topLeft);

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

    const double lineHeight = 10.0;
    final double totalHeight = lineHeight * 3;
    final double offsetY = (totalHeight - height) / 2;

    _hpText  = _buildTextComponent(offsetY: -offsetY + 0);
    _atkText = _buildTextComponent(offsetY: -offsetY + lineHeight);
    _defText = _buildTextComponent(offsetY: -offsetY + lineHeight * 2);

    add(_bg);
    add(_fg);
    add(_hpText);
    add(_atkText);
    add(_defText);
  }

  TextComponent _buildTextComponent({required double offsetY}) {
    return TextComponent(
      text: '',
      anchor: Anchor.topLeft,
      position: Vector2(width + 4, offsetY),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 8,
          color: textColor,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black),
          ],
        ),
      ),
    );
  }

  /// 🌟 外部调用此方法更新属性展示
  void setStats({
    required int currentHp,
    required int maxHp,
    required int atk,
    required int def,
  }) {
    final ratio = maxHp == 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0);
    _fg.scale.x = ratio;

    _hpText.text  = 'HP: ${formatAnyNumber(currentHp)}';
    _atkText.text = 'ATK: ${formatAnyNumber(atk)}';
    _defText.text = 'DEF: ${formatAnyNumber(def)}';
  }
}
