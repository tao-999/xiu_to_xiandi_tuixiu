import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

/// 🌿 静态装饰组件（支持碰撞、逻辑坐标、路径标识、类型标签、tileKey）
class FloatingIslandStaticDecorationComponent extends SpriteComponent
    with CollisionCallbacks {
  FloatingIslandStaticDecorationComponent({
    required Sprite sprite,
    required Vector2 size,
    required Vector2 worldPosition,
    required Vector2 logicalOffset,
    this.spritePath,
    this.type,
    this.tileKey, // ✅ 新增：每个静态资源所属 tile（如 '42_66'）
    this.ignoreAutoPriority = false, // ✅ 新增：是否跳过自动排序
    Anchor anchor = Anchor.center,
  }) : super(
    sprite: sprite,
    size: size,
    anchor: anchor,
    position: worldPosition - logicalOffset, // ✅ 初始化视觉位置
    priority: 10,
  ) {
    _worldPosition = worldPosition;
  }

  /// 🌍 世界坐标（逻辑坐标，用于定位、排序）
  late Vector2 _worldPosition;
  Vector2 get worldPosition => _worldPosition;
  set worldPosition(Vector2 value) => _worldPosition = value;

  /// 🖼️ 当前贴图路径（便于后续切换或识别）
  String? spritePath;

  /// 🔖 类型字段（如 tree / rock / npc_statue / treasure_chest）
  String? type;

  /// 🧩 所属 tileKey（如 "42_66"），用于持久化判断（如宝箱开启状态）
  String? tileKey;

  /// 🚫 是否跳过自动 Y 排序（由 StaticSpriteEntry 的 priority 决定是否赋值）
  bool ignoreAutoPriority = false;

  /// 🎯 自定义碰撞回调（可用于特效或互动逻辑）
  void Function(Set<Vector2> intersectionPoints, PositionComponent other)?
  onCustomCollision;

  /// 🧭 更新组件的视觉位置（地图移动时调用）
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
