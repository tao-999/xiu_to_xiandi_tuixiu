import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';

Future<String> getMeditationImagePath(Character player) async {
  final isFemale = player.gender == 'female';
  final baseName = isFemale ? 'dazuo_female' : 'dazuo_male';

  final equipped = await WeaponsStorage.loadWeaponsEquippedBy(player.id);

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

  return 'assets/images/${baseName}${suffix}.png';
}
