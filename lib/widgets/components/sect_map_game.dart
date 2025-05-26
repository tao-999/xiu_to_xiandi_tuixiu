import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'dart:ui' as ui;
import 'package:xiu_to_xiandi_tuixiu/widgets/effects/aura_effect.dart';

class SectMapGame extends FlameGame with TapDetector {
  late VerticalMap verticalMap;

  @override
  Future<void> onLoad() async {
    verticalMap = VerticalMap();
    add(verticalMap);
    // ✅ 灵气在游戏层，才会固定贴在摄像头范围，永远可见！
    add(AuraCloudEffect(
      density: 1,
      interval: 0.5,
    ));
  }

  @override
  void onTapDown(TapDownInfo info) {
    final tapY = info.eventPosition.global.y;
    final screenHeight = size.y;

    if (tapY < screenHeight / 2) {
      verticalMap.scrollDown(); // ✅ 点击上 → 地图下移（展示更上面）
    } else {
      verticalMap.scrollUp();   // ✅ 点击下 → 地图上移（防止拉出底部）
    }
  }
}

class VerticalMap extends PositionComponent with HasGameRef<FlameGame> {
  final List<SpriteComponent> chunks = [];
  final double chunkHeight = 2048;
  final int preloadChunks = 3;
  late Sprite bgSprite;

  @override
  Future<void> onLoad() async {
    final ui.Image image = await gameRef.images.load('sect_map_bg.png');
    bgSprite = Sprite(image);

    for (int i = 0; i < preloadChunks; i++) {
      final chunk = _createChunk(-i);
      chunks.insert(0, chunk);
      add(chunk);
    }

    size = Vector2.all(999999);
    position = Vector2(0, gameRef.size.y - chunkHeight); // 地图底部贴屏幕底部
  }

  SpriteComponent _createChunk(int index) {
    return SpriteComponent()
      ..sprite = bgSprite
      ..size = Vector2(gameRef.size.x, chunkHeight)
      ..position = Vector2(0, index * chunkHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final topMostY = chunks.first.position.y;
    final visibleTop = -position.y;

    if (visibleTop < topMostY + chunkHeight / 2) {
      final newIndex = (topMostY ~/ chunkHeight) - 1;
      final newChunk = _createChunk(newIndex);
      chunks.insert(0, newChunk);
      add(newChunk);
    }
  }

  void scrollUp() {
    final bottomEdge = position.y + chunks.last.position.y + chunkHeight;
    final screenBottom = gameRef.size.y;

    if (bottomEdge <= screenBottom) return; // 禁止再下移（防止底部露黑）
    position.y -= 100;
  }

  void scrollDown() {
    position.y += 100; // 上翻地图（展示上方新地图）
  }
}
