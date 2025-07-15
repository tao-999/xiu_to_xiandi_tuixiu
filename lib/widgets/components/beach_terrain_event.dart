import 'package:flame/components.dart';
import 'package:flame/game.dart';

class BeachTerrainEvent {
  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    // 🌟这里写你沙滩事件的逻辑
    // 比如弹个提示、生成个宝箱、增加好感度等

    // 示例：返回true代表有事件
    return false;
  }
}
