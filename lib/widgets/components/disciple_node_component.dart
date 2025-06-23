import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as flutter;

class DiscipleNodeComponent extends PositionComponent {
  final String id;
  final String name;
  final String realm;
  final String imagePath;
  String? role;

  DiscipleNodeComponent({
    required this.id,
    required this.name,
    required this.realm,
    required this.imagePath,
    this.role,
    required Vector2 position,
    Vector2? size,
  }) {
    this.size = size ?? Vector2(48, 48);
    anchor = Anchor.center;
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    final fixedPath = imagePath.startsWith('assets/')
        ? imagePath.substring('assets/images/'.length)
        : imagePath;

    final sprite = await Sprite.load(fixedPath);
    final originalSize = sprite.srcSize;

    final targetAvatarSize = 32.0;
    final scale = targetAvatarSize / (originalSize.x > originalSize.y
        ? originalSize.x
        : originalSize.y);

    final avatarSize = originalSize * scale;

    final avatar = SpriteComponent(
      sprite: sprite,
      size: avatarSize,
      position: Vector2(
        (size.x - avatarSize.x) / 2,
        10,
      ),
    );

    add(avatar);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final nameStyle = const flutter.TextStyle(
      color: flutter.Colors.white,
      fontSize: 9,
      height: 1.0,
    );

    _drawCenteredText(
      canvas,
      name,
      nameStyle,
      dy: 0,
    );

    if (role != null && role != '弟子') {
      final roleStyle = flutter.TextStyle(
        color: _getRoleColor(role!),
        fontSize: 9,
        height: 1.0,
      );

      _drawCenteredText(
        canvas,
        role!,
        roleStyle,
        dy: size.y - 4, // ✅ 下移，防止撞图
      );
    }
  }

  /// 🎯 居中绘制文字
  void _drawCenteredText(Canvas canvas, String text, flutter.TextStyle style, {required double dy}) {
    final tp = flutter.TextPainter(
      text: flutter.TextSpan(text: text, style: style),
      textAlign: flutter.TextAlign.center,
      textDirection: flutter.TextDirection.ltr,
    )..layout();

    final dx = (size.x - tp.width) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  flutter.Color _getRoleColor(String role) {
    switch (role) {
      case '长老':
        return flutter.Colors.redAccent;
      case '执事':
        return flutter.Colors.green;
      default:
        return flutter.Colors.white;
    }
  }

  bool containsPoint(Vector2 pointInWorld) {
    final rect = toRect();
    return rect.contains(Offset(pointInWorld.x, pointInWorld.y));
  }

  void updateRole(String? newRole) {
    role = newRole;
  }
}
