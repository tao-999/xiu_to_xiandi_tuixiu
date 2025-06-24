// 📂 lib/utils/player_sprite_util.dart

import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';

/// 获取当前装备贴图路径（含武器、防具判定）
Future<String> getEquippedSpritePath(String gender, String playerId) async {
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
