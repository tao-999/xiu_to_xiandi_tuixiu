import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class FloatingLingShiPopupComponent extends PositionComponent {
  final String text;
  final String imagePath;
  final double duration;
  late SpriteComponent _icon;
  late TextComponent _label;
  late RectangleComponent _background;

  double _elapsed = 0;

  FloatingLingShiPopupComponent({
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

    debugPrint('✨加载灵石图片: $imagePath');

    final sprite = await Sprite.load(imagePath.replaceFirst('assets/images/', ''));

    // 🔹创建 TextPaint
    final textRenderer = TextPaint(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1,1))
        ],
      ),
    );

    // 🔹用 TextPainter 测量文字宽度
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textRenderer.style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;

    // 🌟整体宽度 = 图标(20) + 间距(8) + 文字 + padding(左右各6)
    final totalWidth = 20 + 8 + textWidth + 12;

    // 🌟设定容器尺寸
    size = Vector2(totalWidth, 24);

    // 🌟背景矩形
    _background = RectangleComponent(
      size: size.clone(),
      paint: Paint()..color = Colors.black.withOpacity(0.6),
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
    );

    // 🌟图标
    _icon = SpriteComponent()
      ..sprite = sprite
      ..size = Vector2.all(20)
      ..anchor = Anchor.centerLeft
      ..position = Vector2(6, size.y / 2);

    // 🌟文字
    _label = TextComponent(
      text: text,
      textRenderer: textRenderer,
      anchor: Anchor.centerLeft,
      position: Vector2(6 + 20 + 2, size.y / 2),
    );

    // ⭐先加背景，再加图标，再加文字
    add(_background);
    add(_icon);
    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= 20 * dt;

    if (_elapsed >= duration) {
      removeFromParent();
    }
  }
}
