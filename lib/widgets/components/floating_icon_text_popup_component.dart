import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 通用“图标 + 文本”漂浮提示
class FloatingIconTextPopupComponent extends PositionComponent {
  final String text;
  final String imagePath;
  final double duration;

  late SpriteComponent _icon;
  late TextComponent _label;
  late RectangleComponent _background;

  double _elapsed = 0;

  FloatingIconTextPopupComponent({
    required this.text,
    required this.imagePath,
    required Vector2 position,
    this.duration = 2,
  }) {
    this.position = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final sprite = await Sprite.load(
      imagePath.replaceFirst('assets/images/', ''),
    );

    final textRenderer = TextPaint(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
      ),
    );

    // 预计算文字宽度
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textRenderer.style),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;
    final totalWidth = 20 + 8 + textWidth + 12; // 图标20 + 间距8 + 文字 + padding(6*2)
    size = Vector2(totalWidth, 24);

    _background = RectangleComponent(
      size: size.clone(),
      paint: Paint()..color = Colors.black.withOpacity(0.6),
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
    );

    _icon = SpriteComponent()
      ..sprite = sprite
      ..size = Vector2.all(20)
      ..anchor = Anchor.centerLeft
      ..position = Vector2(6, size.y / 2);

    _label = TextComponent(
      text: text,
      textRenderer: textRenderer,
      anchor: Anchor.centerLeft,
      position: Vector2(6 + 20 + 8, size.y / 2),
    );

    add(_background);
    add(_icon);
    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= 20 * dt; // 上浮

    if (_elapsed >= duration) {
      removeFromParent();
    }
  }
}
