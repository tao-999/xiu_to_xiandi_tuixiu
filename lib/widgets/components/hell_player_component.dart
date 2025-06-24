import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/facing_utils.dart'; // ✅ 引入封装的朝向逻辑

class HellPlayerComponent extends SpriteComponent {
  HellPlayerComponent() : super(anchor: Anchor.center);

  Vector2? targetPosition;
  final double moveSpeed = 200.0;

  static const double defaultCorrection = math.pi / 12;

  @override
  Future<void> onLoad() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;

    final spritePath = await _getEquippedSpriteFileName(player.gender, player.id);
    sprite = await Sprite.load(spritePath);

    final sizeMultiplier = await PlayerStorage.getSizeMultiplier();
    size = Vector2.all(24.0 * sizeMultiplier);

    position = Vector2.all(1024);

    angle = defaultCorrection; // ✅ 补正默认贴图角度
  }

  @override
  void update(double dt) {
    super.update(dt);

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
  }

  /// ✅ 设置移动目标 + 角度朝向更新
  void moveTo(Vector2 target) {
    targetPosition = target;
    final delta = target - position;

    final facing = FacingUtils.calculateFacing(delta);
    angle = facing['angle'];
    scale.x = facing['scaleX'];
  }

  /// ✅ 装备贴图路径加载
  Future<String> _getEquippedSpriteFileName(String gender, String playerId) async {
    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(playerId);
    final hasWeapon = equipped.any((w) => w.type == 'weapon');
    final hasArmor = equipped.any((w) => w.type == 'armor');

    String suffix = '';
    if (hasWeapon && hasArmor) {
      suffix = '_weapon_armor';
    } else if (hasWeapon) {
      suffix = '_weapon';
    } else if (hasArmor) {
      suffix = '_armor';
    }

    return 'icon_youli_${gender}${suffix}.png';
  }
}
