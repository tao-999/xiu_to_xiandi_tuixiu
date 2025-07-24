import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../components/floating_island_dynamic_mover_component.dart';

/// 🚀 专用于逻辑坐标系统的平滑移动效果（作用在 logicalPosition 上）
class LogicalMoveEffect extends ComponentEffect {
  final Vector2 targetPosition; // ✅ 改名，避免与父类冲突
  final Vector2 start;
  final Vector2 delta;
  final FloatingIslandDynamicMoverComponent npc;

  LogicalMoveEffect({
    required this.npc,
    required this.targetPosition,
    required EffectController controller,
  })  : start = npc.logicalPosition.clone(),
        delta = targetPosition - npc.logicalPosition,
        super(controller);

  @override
  void apply(double progress) {
    npc.logicalPosition = start + delta * progress;
  }

  @override
  void onFinish() {
    npc.logicalPosition = targetPosition;
    npc.isMoveLocked = false;
    super.onFinish();
  }
}
