import 'package:flame/components.dart';

class HellMonsterComponent extends SpriteComponent {
  final int level;
  final bool isBoss;

  HellMonsterComponent({
    required this.level,
    this.isBoss = false,
    required Vector2 position,
  }) : super(
    position: position,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('hell/diyu_$level.png');

    size = isBoss
        ? Vector2.all(32) * 2.5 // BOSS 放大 2.5 倍
        : Vector2.all(32);       // 普通怪物尺寸
  }
}
