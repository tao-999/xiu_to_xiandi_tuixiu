import 'dart:math' as math;
import 'package:flame/components.dart';

class FacingUtils {
  static const double _correction = math.pi / 12; // +15°

  /// 🧭 计算朝向角度与镜像（scaleX）
  ///
  /// [delta] 为目标方向向量（目标位置 - 当前角色位置）
  /// 返回值为 Map<String, dynamic>，包含：
  /// - angle: double，SpriteComponent 的 angle
  /// - scaleX: double，SpriteComponent 的 scale.x
  static Map<String, dynamic> calculateFacing(Vector2 delta) {
    if (delta.length < 1e-2) {
      return {'angle': 0.0, 'scaleX': 1.0}; // 不动，默认朝向
    }

    final corrected = Vector2(delta.x, -delta.y); // Flame Y轴朝下，修正成数学坐标系
    final isLeft = delta.x < 0;

    Vector2 base = isLeft
        ? Vector2(-1, math.tan(-_correction)) // ↙️ 左下为默认朝向
        : Vector2(1, math.tan(-_correction));  // ↘️ 右下为默认朝向

    final angleFromBase = corrected.angleToSigned(base);
    final angle = angleFromBase + _correction;
    final scaleX = isLeft ? -1.0 : 1.0;

    return {'angle': angle, 'scaleX': scaleX};
  }
}
