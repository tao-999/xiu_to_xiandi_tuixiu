import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/favorability_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/jinkuang_collision_handler.dart';
import 'package:xiu_to_xiandi_tuixiu/logic/collision/ling_shi_collision_handler.dart';
import '../logic/collision/baoxiang1_collision_handler.dart';
import '../logic/collision/boss1_collision_handler.dart';
import '../logic/collision/boss2_collision_handler.dart';
import '../logic/collision/boss3_collision_handler.dart';
import '../logic/collision/danyao1_collision_handler.dart';
import '../logic/collision/fate_recruit_charm1_collision_handler.dart';
import '../logic/collision/gongfa1_collision_handler.dart';
import '../logic/collision/npc1_collision_handler.dart';
import '../logic/collision/recruit_ticket_collision_handler.dart';
import '../logic/collision/xiancao_collision_handler.dart';
import '../widgets/components/floating_island_dynamic_mover_component.dart';
import '../widgets/components/floating_island_player_component.dart';
import '../widgets/components/floating_island_static_decoration_component.dart';
import '../widgets/components/resource_bar.dart';

class CollisionLogicHandler {
  // ✅ 当前已经触发过的静态组件位置集合
  static final Set<String> _staticCollisionLock = {};

  static void handleCollision({
    required FloatingIslandPlayerComponent player,
    required Vector2 logicalOffset,
    required PositionComponent other,
    required GlobalKey<ResourceBarState> resourceBarKey, // ✅ 新增参数
  }) {
    // ✅ 动态 NPC / 怪物
    if (other is FloatingIslandDynamicMoverComponent) {

      switch (other.type) {
        case 'npc_1':
          Npc1CollisionHandler.handle(
            playerLogicalPosition: player.logicalPosition,
            npc: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'boss_1':
          Boss1CollisionHandler.handle(
            player: player,
            boss: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'boss_2':
          Boss2CollisionHandler.handle(
            player: player,
            boss: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'gongfa_1':
          Gongfa1CollisionHandler.handle(
            player: player,
            gongfaBook: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'danyao':
          Danyao1CollisionHandler.handle(
            player: player,
            danyao: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'boss_3':
          Boss3CollisionHandler.handle(
            player: player,
            boss: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'charm_1':
          FateRecruitCharm1CollisionHandler.handle(
            player: player,
            charm: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'recruit_ticket':
          RecruitTicketCollisionHandler.handle(
            player: player,
            charm: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'xiancao':
          XiancaoCollisionHandler.handle(
            player: player,
            xiancao: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'favorability':
          FavorabilityCollisionHandler.handle(
            player: player,
            favorItem: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'lingshi':
          LingShiCollisionHandler.handle(
            player: player,
            lingShi: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        case 'jinkuang':
          JinkuangCollisionHandler.handle(
            player: player,
            jinkuang: other,
            resourceBarKey: resourceBarKey,
          );
          break;
        default:
          _handleMonsterCollision(player.logicalPosition, other);
      }
    }

    // ✅ 静态装饰物
    else if (other is FloatingIslandStaticDecorationComponent) {

      final key = _getComponentKey(other);
      if (_staticCollisionLock.contains(key)) return;
      _staticCollisionLock.add(key);

      switch (other.type) {
        case 'baoxiang_1':
          Baoxiang1CollisionHandler.handle(
            playerLogicalPosition: player.logicalPosition,
            chest: other,
            logicalOffset: logicalOffset,
            resourceBarKey: resourceBarKey,
          );
          break;
        default:
          return;
      }
    }
  }

  // ✅ 每帧调用清理“离开范围”的组件锁
  static void updateLockStatus(Vector2 playerPosition, List<FloatingIslandStaticDecorationComponent> components) {
    _staticCollisionLock.removeWhere((key) {
      FloatingIslandStaticDecorationComponent? comp;

      try {
        comp = components.firstWhere((c) => _getComponentKey(c) == key);
      } catch (_) {
        comp = null;
      }

      if (comp == null) return true;

      final dist = (playerPosition - comp.worldPosition).length;
      return dist > 32;
    });
  }

  static String _getComponentKey(FloatingIslandStaticDecorationComponent comp) {
    return '${comp.spritePath}_${comp.worldPosition.x.toInt()}_${comp.worldPosition.y.toInt()}';
  }

  static void _handleMonsterCollision(Vector2 playerPosition, FloatingIslandDynamicMoverComponent monster) {
    final delta = playerPosition - monster.logicalPosition;

    final rebound = delta.length > 0.01
        ? delta.normalized()
        : (Vector2.random() - Vector2(0.5, 0.5)).normalized();

    // 🌀 推开怪物
    monster.logicalPosition -= rebound * 10;

    // ✅ 判断朝向
    if (delta.length > 0.01) {
      final preferRight = playerPosition.x < monster.logicalPosition.x;
      monster.pickNewTarget(preferRight: preferRight);
    } else {
      // ✅ 玩家和怪物坐标重合，随机方向
      monster.pickNewTarget();
    }
  }

}
