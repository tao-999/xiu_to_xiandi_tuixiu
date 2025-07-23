import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

/// 🌿 静态装饰组件（支持碰撞、逻辑坐标和路径标识）
class FloatingIslandStaticDecorationComponent extends SpriteComponent
    with CollisionCallbacks {
  FloatingIslandStaticDecorationComponent({
    required Sprite sprite,
    required Vector2 size,
    required Vector2 worldPosition,
    required Vector2 logicalOffset, // ✅ 新增参数
    String? spritePath,
    Anchor anchor = Anchor.center,
  }) : super(
    sprite: sprite,
    size: size,
    anchor: anchor,
    position: worldPosition - logicalOffset, // ✅ 初始化视觉位置
  ) {
    _worldPosition = worldPosition;
    this.spritePath = spritePath;
  }

  /// 逻辑坐标（世界坐标）
  late Vector2 _worldPosition;

  Vector2 get worldPosition => _worldPosition;

  set worldPosition(Vector2 value) => _worldPosition = value;

  /// 当前贴图路径（用于辨识）
  String? spritePath;

  /// 自定义碰撞回调
  void Function(Set<Vector2> intersectionPoints, PositionComponent other)?
  onCustomCollision;

  /// 更新显示坐标（可用于移动时刷新）
  void updateVisualPosition(Vector2 logicalOffset) {
    position = _worldPosition - logicalOffset;
  }

  @override
  void onCollision(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    if (onCustomCollision != null) {
      onCustomCollision!(intersectionPoints, other);
    }
    super.onCollision(intersectionPoints, other);
  }
}
