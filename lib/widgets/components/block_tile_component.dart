import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BlockTileComponent extends PositionComponent {
  final int row;
  final int col;
  final double tileSize;

  BlockTileComponent({
    required this.row,
    required this.col,
    required this.tileSize,
    Vector2? position,
  }) {
    this.position = position ?? Vector2(col * tileSize, row * tileSize);
    size = Vector2.all(tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // ✅ 画背景
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFF5E5C3),
    ));

    // ✅ 加边框
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    ));

    // ✅ 加编号文字组件
    final int number = row * 1000 + col + 1; // 可换成 row * colCount + col + 1
    add(
      TextComponent(
        text: '$number',
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
