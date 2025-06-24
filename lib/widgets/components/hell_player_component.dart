import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/facing_utils.dart';

import '../../models/character.dart';
import '../../utils/player_sprite_util.dart';
import '../effects/lightning_effect_component.dart';
import 'hp_bar_wrapper.dart';
import 'hell_monster_component.dart';

class HellPlayerComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  HellPlayerComponent({
    required this.safeZoneCenter,
    required this.safeZoneRadius,
  }) : super(anchor: Anchor.center);

  Vector2? targetPosition;
  final double moveSpeed = 200.0;
  static const double defaultCorrection = math.pi / 12;

  late Character _player;
  late int hp;
  late int maxHp;
  late int atk;
  late int def;

  late HpBarWrapper _hpBar;

  double _lightningCooldown = 0.0;
  bool _isReleasingLightning = false;

  final Vector2 safeZoneCenter;
  final double safeZoneRadius;

  bool get isInSafeZone =>
      (absolutePosition - safeZoneCenter).length <= safeZoneRadius;

  @override
  Future<void> onLoad() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;
    _player = player;

    final spritePath = await getEquippedSpritePath(player.gender, player.id);
    sprite = await Sprite.load(spritePath);

    final sizeMultiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(18.0 * sizeMultiplier);
    position = Vector2.all(1024);
    angle = defaultCorrection;

    maxHp = PlayerStorage.getHp(_player);
    hp = maxHp;
    atk = PlayerStorage.getAtk(_player);
    def = PlayerStorage.getDef(_player);

    add(RectangleHitbox()..collisionType = CollisionType.active);

    _hpBar = HpBarWrapper(ratio: () => hp / maxHp)
      ..scale.x = 1
      ..priority = 999;
    Future.microtask(() {
      parent?.add(_hpBar);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hpBar.position = absolutePosition + Vector2(0, -size.y / 2 - 6);

    if (targetPosition != null) {
      final toTarget = targetPosition! - position;
      final distance = toTarget.length;
      if (distance < moveSpeed * dt) {
        position = targetPosition!;
        targetPosition = null;
      } else {
        position += toTarget.normalized() * moveSpeed * dt;
      }
    }

    _lightningCooldown -= dt;

    if (_lightningCooldown <= 0 && !_isReleasingLightning && !isInSafeZone) {
      final monsters = parent?.children.whereType<HellMonsterComponent>().toList() ?? [];

      final anyInRange = monsters.any(
            (m) => (m.absolutePosition - absolutePosition).length <= 128,
      );

      if (anyInRange) {
        _isReleasingLightning = true;
        _fireLightning(monsters);
      }
    }
  }

  void moveTo(Vector2 target) {
    targetPosition = target;
    final delta = target - position;
    final facing = FacingUtils.calculateFacing(delta);
    angle = facing['angle'];
    scale.x = facing['scaleX'];
  }

  void receiveDamage(int damage) {
    final reduced = (damage - def).clamp(0, damage);
    hp = (hp - reduced).clamp(0, maxHp);
    if (hp <= 0) {
      print('☠️ 玩家死亡');
    }
  }

  int get power => atk + def + hp ~/ 10;

  Future<void> _fireLightning(List<HellMonsterComponent> monsters) async {
    final layer = await PlayerStorage.getCultivationLayer();
    final count = (layer ~/ 10).clamp(1, 999);

    // 筛选进入范围内的怪物（范围从128改为500）
    final targetsInRange = monsters.where(
          (m) => (m.absolutePosition - absolutePosition).length <= 500,  // 改为500
    ).toList();

    // 按角色到怪物的距离进行排序，最近的怪物在前
    targetsInRange.sort((a, b) =>
        (a.absolutePosition - absolutePosition).length.compareTo(
            (b.absolutePosition - absolutePosition).length));

    // 选择需要攻击的怪物数量（根据玩家境界）
    final shootCount = count.clamp(1, targetsInRange.length);

    final random = math.Random();  // 使用 math.Random()

    // 假设地图顶部Y坐标为 -50（屏幕外位置）
    final screenTopY = -50.0;

    for (int i = 0; i < shootCount; i++) {
      final target = targetsInRange[i];

      // 获取目标怪物的位置
      final targetPosition = target.absolutePosition;

      // 计算闪电的起点（从屏幕顶部外，X在目标附近随机偏移）
      final startX = targetPosition.x + random.nextDouble() * 60 - 30;  // 随机偏移±30
      final start = Vector2(startX, screenTopY);

      // 计算闪电的方向：从起点指向目标怪物
      final dir = (targetPosition - start).normalized();

      // 计算闪电的最大射程（目标距离）
      final maxDistance = (targetPosition - start).length;

      // 打印调试：查看角色当前坐标和闪电的起点、目标位置及怪物编号
      print('⚡ 闪电起点: $start, 角色当前位置: $absolutePosition, 目标怪物位置: ${target.absolutePosition}');
      print('⚡ 闪电方向: $dir, 最大射程: $maxDistance');
      print('⚡ 目标怪物编号: ${target.id}');  // 打印怪物编号

      final lightning = LightningEffectComponent(
        start: start,
        direction: dir,
        maxDistance: maxDistance, // 使用目标距离作为最大射程
      );

      parent?.add(lightning);  // 添加闪电特效

      print('⚡ 闪电第${i + 1}道从天而降击中怪物 ${target.id} at $targetPosition');  // 打印击中的怪物编号

      await Future.delayed(const Duration(milliseconds: 30));  // 分帧发射，不卡顿
    }

    await Future.delayed(const Duration(milliseconds: 250));

    _lightningCooldown = 1.0;
    _isReleasingLightning = false;
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    print('💥 与 ${other.runtimeType} 碰撞');
    super.onCollision(points, other);
  }
}
