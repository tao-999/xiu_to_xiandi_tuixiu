// 📁 utils/floating_static_event_state_util.dart
import 'package:flame/components.dart';
import '../services/treasure_chest_storage.dart';

/// 🌟 通用静态事件状态判断工具类（异步版）
class FloatingStaticEventStateUtil {
  /// ✅ 贴图路径判断（异步，无缓存，实时查询 Hive）
  static Future<String> getEffectiveSpritePath({
    required String originalPath,
    required Vector2 worldPosition,
    required String? type,
    String? tileKey, // ✅ 新增
  }) async {
    switch (type) {
      case 'baoxiang_1':
        final isOpen = tileKey != null &&
            await TreasureChestStorage.isOpenedTile(tileKey); // ✅ 改为 await

        print('🔍 [贴图判断] 宝箱类型 → tileKey=($tileKey), pos=($worldPosition), opened=$isOpen');

        return isOpen
            ? 'floating_island/beach_2_open.png'
            : originalPath;

      default:
        return originalPath;
    }
  }
}