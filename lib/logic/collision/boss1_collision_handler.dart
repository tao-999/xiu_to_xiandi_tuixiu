import 'package:flame/components.dart';
import '../../widgets/components/floating_island_dynamic_mover_component.dart';

class Boss1CollisionHandler {
  static void handle({
    required Vector2 playerLogicalPosition,
    required FloatingIslandDynamicMoverComponent boss,
    required Vector2 logicalOffset,
  }) {
    print('👹 [Boss1] 玩家靠近 Boss → pos=${boss.logicalPosition}');
    print('🧾 Boss 属性：HP=${boss.hp}, ATK=${boss.atk}, DEF=${boss.def}');
  }
}
