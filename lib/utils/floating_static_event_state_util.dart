// 📁 utils/floating_static_event_state_util.dart
import 'package:flame/components.dart';
import '../services/treasure_chest_storage.dart';

/// 🌟 通用静态事件状态判断工具类（同步版）
class FloatingStaticEventStateUtil {
  /// ✅ 贴图路径判断（同步，依赖缓存）
  static String getEffectiveSpritePath({
    required String originalPath,
    required Vector2 worldPosition,
    required String? type,
  }) {
    switch (type) {
      case 'baoxiang_1':
        final isOpen = TreasureChestStorage.isOpenedSync(worldPosition);

        // 🧾 打印调试信息
        print('🔍 [贴图判断] 宝箱类型 → pos=($worldPosition), opened=$isOpen, result=${isOpen ? 'floating_island/beach_2_open.png' : originalPath}');

        return isOpen
            ? 'floating_island/beach_2_open.png'
            : originalPath;

      default:
        return originalPath;
    }
  }
}
