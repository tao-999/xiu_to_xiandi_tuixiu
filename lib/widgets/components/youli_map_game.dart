import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_huanyue_explore.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_chiyangu.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_xianling_qizhen.dart';

class YouliMapGame extends FlameGame {
  final BuildContext context;
  late final SpriteComponent bg;
  final List<_EntryIcon> entryIcons = [];

  YouliMapGame(this.context);

  @override
  Future<void> onLoad() async {
    final screen = canvasSize;

    bg = SpriteComponent()
      ..sprite = await loadSprite('bg_map_youli_horizontal.webp')
      ..size = Vector2(3000, 2400)
      ..anchor = Anchor.topLeft
      ..scale = Vector2.all(0.45)
      ..position = Vector2(0, screen.y - 2400 * 0.45);
    add(bg);

    await _addEntry('youli_fanchenshiji.png', Vector2(500, 1900));
    await _addEntry('youli_huanyueshan.png', Vector2(700, 1350), onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HuanyueExplorePage()),
      );
    });
    await _addEntry('youli_ciyangu.png', Vector2(400, 800), onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChiyanguPage()),
      );
    });
    await _addEntry('youli_fukongxiandao.png', Vector2(1100, 400));
    await _addEntry('youli_dengtianti.png', Vector2(1600, 800));
    await _addEntry('youli_youmingguiku.png', Vector2(2700, 1800));
    await _addEntry('youli_xianlingqizhen.png', Vector2(1350, 2200), onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const XianlingQizhenPage()),
      );
    });

    add(DragMap(
      onDragged: _onDragged,
      onTap: _handleTap,
    ));
  }

  Future<void> _addEntry(String imageName, Vector2 position, {void Function()? onTap}) async {
    final icon = _EntryIcon(
      sprite: await loadSprite(imageName),
      position: position,
      name: _extractName(imageName),
      onTap: onTap,
    );
    entryIcons.add(icon);
    bg.add(icon);
  }

  String _extractName(String imageName) {
    if (imageName.contains('huanyueshan')) return '幻月山';
    if (imageName.contains('fanchenshiji')) return '修仙集市';
    if (imageName.contains('ciyangu')) return '赤炎谷';
    if (imageName.contains('fukongxiandao')) return '浮空仙岛';
    if (imageName.contains('dengtianti')) return '登天梯';
    if (imageName.contains('youmingguiku')) return '幽冥鬼窟';
    if (imageName.contains('xianlingqizhen')) return '仙灵棋阵';
    return '未知区域';
  }

  void _onDragged(Vector2 delta) {
    bg.position += delta;
    _clampPosition();
  }

  void _clampPosition() {
    final screen = canvasSize;
    final scaledSize = bg.size.clone()..multiply(bg.scale);

    final minX = screen.x - scaledSize.x;
    final minY = screen.y - scaledSize.y;
    const maxX = 0.0;
    const maxY = 0.0;

    bg.position.x = bg.position.x.clamp(minX, maxX);
    bg.position.y = bg.position.y.clamp(minY, maxY);
  }

  void _handleTap(Vector2 tapInScreen) {
    for (final icon in entryIcons) {
      final center = icon.absolutePosition;
      final size = icon.size; // ✅ 不要乘 bg.scale 了！

      final topLeft = center - size / 2;

      final hitbox = Rect.fromLTWH(
        topLeft.x,
        topLeft.y,
        size.x,
        size.y,
      );

      if (hitbox.contains(Offset(tapInScreen.x, tapInScreen.y))) {
        icon.onTap?.call();
        break;
      }
    }
  }
}

class _EntryIcon extends PositionComponent {
  final void Function()? onTap;

  _EntryIcon({
    required Sprite sprite,
    required Vector2 position,
    required String name,
    this.onTap,
  }) {
    this.position = position;
    anchor = Anchor.center;

    // 🟡 固定宽度 256，高度按原图比例缩放
    const double fixedWidth = 206;
    final originalSize = sprite.srcSize;
    final scale = fixedWidth / originalSize.x;
    final scaledHeight = originalSize.y * scale;

    final textHeight = 32.0;
    size = Vector2(fixedWidth, scaledHeight + textHeight);

    final icon = SpriteComponent(
      sprite: sprite,
      size: Vector2(fixedWidth, scaledHeight),
      anchor: Anchor.center,
      position: Vector2(0, textHeight / 2),
    );

    final label = TextComponent(
      text: name,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -scaledHeight / 2.3), // 文字在图标上方
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'ZcoolCangEr',
          shadows: [
            Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
    );

    addAll([icon, label]);
  }
}