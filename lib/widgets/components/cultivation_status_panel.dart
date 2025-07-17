import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/models/weapon.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/cultivation_level.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/meditation_widget.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/dialogs/equip_selection_dialog.dart';
import 'cultivation_progress_bar.dart';

class CultivationStatusPanel extends StatefulWidget {
  final Character player;
  final CultivationLevelDisplay display;
  final bool showAura;
  final VoidCallback? onAuraComplete;

  const CultivationStatusPanel({
    super.key,
    required this.player,
    required this.display,
    this.showAura = false,
    this.onAuraComplete,
  });

  @override
  State<CultivationStatusPanel> createState() => _CultivationStatusPanelState();
}

class _CultivationStatusPanelState extends State<CultivationStatusPanel> {
  late Character _player;
  bool _hasAccessory = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _checkAccessoryEquipped();
  }

  Future<void> _checkAccessoryEquipped() async {
    final list = await WeaponsStorage.loadWeaponsEquippedBy(_player.id);

    final hasAccessory = list.any((w) => w.type == 'accessory');

    setState(() {
      _hasAccessory = hasAccessory;
    });
  }

  void _handleEquipSelected(Weapon weapon) async {
    final playerId = _player.id;

    final allWeapons = await WeaponsStorage.loadWeaponsEquippedBy(playerId);
    for (final w in allWeapons) {
      if (w.key != weapon.key && w.type == weapon.type) {
        await WeaponsStorage.unequipWeapon(w);
      }
    }

    await WeaponsStorage.equipWeapon(
      weapon: weapon,
      ownerId: playerId,
    );
    await PlayerStorage.updateField('equippedWeaponId', weapon.key);

    final updatedPlayer = await PlayerStorage.getPlayer();
    if (updatedPlayer == null) return;

    setState(() {
      _player = updatedPlayer;
    });

    await _checkAccessoryEquipped();
  }

  Future<String> getMeditationImagePath() async {
    final isFemale = _player.gender == 'female';
    final baseName = isFemale ? 'dazuo_female' : 'dazuo_male';

    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(_player.id);

    final hasWeapon = equipped.any((w) => w.type == 'weapon');
    final hasArmor  = equipped.any((w) => w.type == 'armor');

    String suffix = '';
    if (hasWeapon && hasArmor) {
      suffix = '_weapon_armor';
    } else if (hasWeapon) {
      suffix = '_weapon';
    } else if (hasArmor) {
      suffix = '_armor';
    }

    final imagePath = 'assets/images/${baseName}${suffix}.png';

    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            "${widget.display.realm}滔天大修士",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'ZcoolCangEr',
              shadows: [
                Shadow(blurRadius: 2, offset: Offset(1, 1), color: Colors.black26),
              ],
            ),
          ),
        ),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // ✅ 莲花台：图层永远在下面
            if (_hasAccessory)
              Positioned(
                bottom: -100,
                child: Image.asset(
                  'assets/images/wuqi_xueliang.png',
                  width: 180,
                  height: 180,
                ),
              ),

            // ✅ 打坐角色
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => EquipSelectionDialog(
                    currentOwnerId: _player.id,
                    onEquipSelected: (selectedWeapon) {
                      Navigator.of(context).pop();
                      _handleEquipSelected(selectedWeapon);
                    },
                    onChanged: () async {
                      await _checkAccessoryEquipped(); // ✅ 重新判断莲花台要不要显示
                    },
                  ),
                );
              },
              child: FutureBuilder<String>(
                future: getMeditationImagePath(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return MeditationWidget(
                    imagePath: snapshot.data!,
                    ready: true,
                    offset: const AlwaysStoppedAnimation(Offset.zero),
                    opacity: const AlwaysStoppedAnimation(1.0),
                    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
                  );
                },
              ),
            ),
          ],
        ),

        CultivationProgressBar(
          current: widget.display.current,
          max: widget.display.max,
          realm: widget.display.realm,
          rank: widget.display.rank,
        ),
      ],
    );
  }
}
