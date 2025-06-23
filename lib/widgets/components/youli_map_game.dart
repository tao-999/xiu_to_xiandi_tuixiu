import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_huanyue_explore.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_chiyangu.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_xianling_qizhen.dart';
import '../../pages/page_market.dart';
import '../../pages/page_naihe_bridge.dart';

class YouliMapGame extends FlameGame {
  final BuildContext context;
  late final SpriteComponent bg;
  final List<_EntryIcon> entryIcons = [];

  YouliMapGame(this.context);

  @override
  Future<void> onLoad() async {
    final screen = canvasSize;

    final sprite = await loadSprite('bg_map_youli_horizontal.webp');
    final originalSize = sprite.srcSize;

    // ✅ 根据屏幕高度计算缩放倍数
    final double scale = screen.y / originalSize.y;

    // ✅ 设置背景尺寸 = 原图尺寸（逻辑大小不变），只缩放显示比例
    bg = SpriteComponent()
      ..sprite = sprite
      ..size = originalSize
      ..scale = Vector2.all(scale)
      ..anchor = Anchor.topLeft;

    // ✅ 居中逻辑：屏幕宽度的一半 - 缩放后地图宽度的一半
    final double mapWidth = originalSize.x * scale;
    final double offsetX = (screen.x - mapWidth) / 2;

    bg.position = Vector2(offsetX.clamp(screen.x - mapWidth, 0), 0); // Y顶对齐，X居中
    add(bg);

    // ✅ 原图坐标，无需缩放
    await _addEntry('youli_fanchenshiji.png', Vector2(800, 850), onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const XiuXianMarketPage()));
    });

    await _addEntry('youli_huanyueshan.png', Vector2(1250, 200), onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HuanyueExplorePage()));
    });

    await _addEntry('youli_ciyangu.png', Vector2(1360, 830), onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChiyanguPage()));
    });

    await _addEntry('youli_fukongxiandao.png', Vector2(900, 500));
    await _addEntry('youli_dengtianti.png', Vector2(200, 250));
    await _addEntry('youli_youmingguiku.png', Vector2(1500, 600));

    await _addEntry('youli_xianlingqizhen.png', Vector2(550, 600), onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const XianlingQizhenPage()));
    });

    await _addEntry('youli_naiheqiao.png', Vector2(400, 800), onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NaiheBridgePage()));
    });

    // ✅ 拖动组件
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
    if (imageName.contains('naiheqiao')) return '奈何桥';
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
      final size = icon.size;

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

    const double fixedWidth = 128;
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

    add(icon);
  }
}
