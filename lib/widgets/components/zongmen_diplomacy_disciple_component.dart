import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as flutter;
import '../../../models/disciple.dart';
import '../../utils/sect_role_limits.dart';

class ZongmenDiplomacyDiscipleComponent extends SpriteComponent
    with CollisionCallbacks {
  final Disciple disciple;
  final Vector2 logicalPosition;

  ZongmenDiplomacyDiscipleComponent({
    required this.disciple,
    required this.logicalPosition,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final originalPath = disciple.imagePath;
    final String relativePath = _normalizeAssetPath(originalPath);

    final loadedSprite = await Sprite.load(relativePath);
    sprite = loadedSprite;

    final imageSize = loadedSprite.srcSize;
    final double aspectRatio = imageSize.y / imageSize.x;

    final double fixedWidth = 48.0;
    final double autoHeight = fixedWidth * aspectRatio;

    size = Vector2(fixedWidth, autoHeight);
    position = logicalPosition.clone();

    add(
      RectangleHitbox()
        ..collisionType = CollisionType.passive,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 🧱 上方显示名字
    _drawCenteredText(
      canvas,
      disciple.name,
      const flutter.TextStyle(
        color: flutter.Colors.white,
        fontSize: 9,
        height: 1.0,
      ),
      dy: -12, // 👈 上移一点，避免盖住贴图
    );

    // 🧱 下方显示职位（排除“弟子”）
    if (disciple.role != null && disciple.role != '弟子') {
      _drawCenteredText(
        canvas,
        disciple.role!,
        flutter.TextStyle(
          color: SectRoleLimits.getRoleColor(disciple.role!),
          fontSize: 9,
          height: 1.0,
        ),
        dy: size.y + 2,
      );
    }
  }

  /// 🎯 居中绘制文字
  void _drawCenteredText(Canvas canvas, String text, flutter.TextStyle style,
      {required double dy}) {
    final tp = flutter.TextPainter(
      text: flutter.TextSpan(text: text, style: style),
      textAlign: flutter.TextAlign.center,
      textDirection: flutter.TextDirection.ltr,
    )..layout();

    final dx = (size.x - tp.width) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  /// 📍地图移动时更新视觉位置
  void updateVisualPosition(Vector2 logicalOffset) {
    position = logicalPosition - logicalOffset;
  }

  String _normalizeAssetPath(String path) {
    if (path.startsWith('assets/images/')) {
      return path.substring('assets/images/'.length);
    }
    return path;
  }
}
