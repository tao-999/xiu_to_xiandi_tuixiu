// lib/widgets/components/chest_component.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class ChestComponent extends SpriteComponent with CollisionCallbacks {
  final Sprite openSprite;
  bool opened = false;

  ChestComponent({
    required Sprite closedSprite,
    required this.openSprite,
    required Vector2 position,
  }) : super(
    sprite: closedSprite,
    size: Vector2.all(48),
    position: position,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void open() {
    if (!opened) {
      sprite = openSprite;
      opened = true;
    }
  }
}
