import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as flutter;

class DiscipleNodeComponent extends PositionComponent {
  final String id;
  final String name;
  final String realm;
  final String imagePath;
  String? role; // ✅ 改成非 final

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

    final targetAvatarSize = 28.0;
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
    final centerX = size.x / 2;

    final textPaint = TextPaint(
      style: const flutter.TextStyle(
        color: flutter.Colors.white,
        fontSize: 9,
        height: 1.0,
      ),
    );

    final title = '$name · $realm';
    final titleOffsetX = centerX - (title.length * 4.5 / 2);
    textPaint.render(canvas, title, Vector2(titleOffsetX, 0));

    if (role != null && role!.isNotEmpty) {
      final roleColor = _getRoleColor(role!);
      final rolePaint = TextPaint(
        style: flutter.TextStyle(
          color: roleColor,
          fontSize: 9,
          height: 1.0,
          fontWeight: flutter.FontWeight.bold,
        ),
      );
      final roleOffsetX = centerX - (role!.length * 4.5 / 2);
      rolePaint.render(canvas, role!, Vector2(roleOffsetX, size.y - 11));
    }
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

  /// ✅ 外部点击判定用
  bool containsPoint(Vector2 pointInWorld) {
    final rect = toRect();
    return rect.contains(Offset(pointInWorld.x, pointInWorld.y));
  }

  /// ✅ 职位刷新方法（改完就自动重绘）
  void updateRole(String? newRole) {
    role = newRole;
  }
}
