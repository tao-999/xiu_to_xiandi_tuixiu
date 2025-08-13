// 📄 lib/utils/global_distance.dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// 取组件的“全局逻辑坐标”（像素），已把 worldBase + logicalPosition 合并，
/// 若组件没有 logicalPosition 字段，则用 position + logicalOffset 还原。
Vector2 getGlobalLogicalPosition({
  required Component comp,
  required FlameGame game,
}) {
  // 1) 尝试拿 logicalPosition（动态字段，很多你自己的组件都有）
  Vector2? logicalPos;
  try {
    final dyn = comp as dynamic;
    final Vector2? lp = dyn.logicalPosition as Vector2?;
    if (lp != null) logicalPos = lp;
  } catch (_) {
    // ignore
  }

  // 2) 拿不到就回退：position + logicalOffset（把“画面坐标”还原为“世界逻辑坐标”）
  if (logicalPos == null) {
    final Vector2 logicalOffset =
        (game as dynamic).logicalOffset as Vector2? ?? Vector2.zero();
    if (comp is PositionComponent) {
      logicalPos = comp.position + logicalOffset;
    } else {
      // 实在拿不到，就把相机中心当作“近似世界坐标”（不至于崩）
      logicalPos = logicalOffset.clone();
    }
  }

  // 3) 合并 worldBase（重基累计），得到“全局坐标”
  final Vector2 worldBase =
      (game as dynamic).worldBase as Vector2? ?? Vector2.zero();
  final Vector2 global = worldBase + logicalPos;

  // 4) 容错：NaN/Inf 直接归零，避免 length() 爆
  if (!global.x.isFinite || !global.y.isFinite) {
    return Vector2.zero();
  }
  return global;
}

/// 返回组件到全局原点(0,0)的“像素距离”
/// —— 已兼容 worldBase 重基；没有 logicalPosition 也会自动还原。
double computeGlobalDistancePx({
  required Component comp,
  required FlameGame game,
}) {
  final g = getGlobalLogicalPosition(comp: comp, game: game);
  final d = g.length;
  return d.isFinite ? d : 0.0;
}
