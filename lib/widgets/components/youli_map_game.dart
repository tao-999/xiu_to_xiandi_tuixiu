import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_maze_2p5d.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart'; // 你封装的组件

class YouliMapGame extends FlameGame {
  final BuildContext context;
  late final SpriteComponent bg;
  final List<_EntryIcon> entryIcons = [];

  YouliMapGame(this.context);

  @override
  Future<void> onLoad() async {
    final screen = canvasSize;

    bg = SpriteComponent()
      ..sprite = await loadSprite('bg_map_youli_horizontal.png')
      ..size = Vector2(3000, 2400)
      ..anchor = Anchor.topLeft
      ..scale = Vector2.all(0.45)
      ..position = Vector2(0, screen.y - 2400 * 0.45);
    add(bg);

    await _addEntry('youli_fanchenshiji.png', Vector2(500, 1900));
    await _addEntry('youli_huanyueshan.png', Vector2(700, 1350), onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const Maze2p5DPage()),
      );
    });
    await _addEntry('youli_ciyangu.png', Vector2(400, 800));
    await _addEntry('youli_fukongxiandao.png', Vector2(1100, 400));
    await _addEntry('youli_dengtianti.png', Vector2(1600, 800));
    await _addEntry('youli_youmingguiku.png', Vector2(2700, 1800));

    // 添加封装好的 DragMap
    add(DragMap(
      onDragged: _onDragged,
      onTap: _handleTap,
    ));
  }

  Future<void> _addEntry(String imageName, Vector2 position, {void Function()? onTap}) async {
    final icon = _EntryIcon(
      sprite: await loadSprite(imageName),
      position: position,
      onTap: onTap,
    );
    entryIcons.add(icon);
    bg.add(icon);
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
    final local = (tapInScreen - bg.position) / bg.scale.x;

    for (final icon in entryIcons) {
      final center = icon.position;
      final halfSize = icon.size.x / 2;
      final hitbox = Rect.fromCenter(
        center: Offset(center.x, center.y),
        width: icon.size.x,
        height: icon.size.y,
      );
      if (hitbox.contains(Offset(local.x, local.y))) {
        icon.onTap?.call();
        break;
      }
    }
  }
}

class _EntryIcon extends SpriteComponent {
  final void Function()? onTap;

  _EntryIcon({
    required Sprite sprite,
    required Vector2 position,
    this.onTap,
  }) {
    this.sprite = sprite;
    size = Vector2.all(256);
    anchor = Anchor.center;
    this.position = position;
  }
}
