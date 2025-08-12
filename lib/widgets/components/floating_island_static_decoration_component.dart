// 📂 lib/widgets/components/floating_island_static_decoration_component.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

/// 🌿 静态装饰组件（支持碰撞、逻辑坐标、路径标识、类型标签、tileKey、移除回调）
class FloatingIslandStaticDecorationComponent extends SpriteComponent
    with CollisionCallbacks {
  FloatingIslandStaticDecorationComponent({
    required Sprite sprite,
    required Vector2 size,
    required Vector2 worldPosition,
    required Vector2 logicalOffset,
    this.spritePath,
    this.type,
    this.tileKey, // 每个静态资源所属 tile（如 '42_66'）
    this.ignoreAutoPriority = false, // 是否跳过自动排序（由外部控制）
    Anchor anchor = Anchor.center,
  }) : super(
    sprite: sprite,
    size: size,
    anchor: anchor,
    position: worldPosition - logicalOffset, // 初始化视觉位置
    priority: 10,
  ) {
    _worldPosition = worldPosition;
  }

  // ===== 位置信息（逻辑/世界） =====
  late Vector2 _worldPosition;
  Vector2 get worldPosition => _worldPosition;
  set worldPosition(Vector2 value) => _worldPosition = value;

  /// 🖼️ 贴图路径（可用于后续替换/识别）
  String? spritePath;

  /// 🔖 类型（tree / rock / npc_statue / treasure_chest ...）
  String? type;

  /// 🧩 所属 tileKey（如 "42_66"）
  String? tileKey;

  /// 🚫 是否跳过自动 Y 排序（外部可改）
  bool ignoreAutoPriority = false;

  /// 🎯 自定义碰撞回调（可选）
  void Function(Set<Vector2> intersectionPoints, PositionComponent other)?
  onCustomCollision;

  /// 🪝 外部可挂的“被移除时回调”（Spawner 用这个做索引清理）
  void Function()? onDespawn;

  /// 同步视觉位置（随相机偏移）
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

  @override
  void onRemove() {
    // 先通知回调，再走父类移除
    try {
      onDespawn?.call();
    } catch (_) {}
    super.onRemove();
  }
}
