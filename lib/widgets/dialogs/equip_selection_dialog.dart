import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/weapon.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';

class EquipSelectionDialog extends StatefulWidget {
  final String currentOwnerId;
  final void Function(Weapon selected) onEquipSelected;
  final void Function()? onChanged;

  const EquipSelectionDialog({
    super.key,
    required this.currentOwnerId,
    required this.onEquipSelected,
    this.onChanged,
  });

  @override
  State<EquipSelectionDialog> createState() => _EquipSelectionDialogState();
}

class _EquipSelectionDialogState extends State<EquipSelectionDialog> {
  List<Weapon> _weapons = [];

  @override
  void initState() {
    super.initState();
    _loadWeapons();
  }

  Future<void> _loadWeapons() async {
    final list = await WeaponsStorage.loadSortedByTimeDesc();
    setState(() => _weapons = list);
  }

  Future<void> _equipWeapon(Weapon weapon) async {
    // 卸下所有当前 owner 的同类型武器
    final allEquipped = await WeaponsStorage.loadWeaponsEquippedBy(widget.currentOwnerId);
    for (final w in allEquipped) {
      if (w.type == weapon.type && w.key != weapon.key) {
        await WeaponsStorage.unequipWeapon(w);
      }
    }

    await WeaponsStorage.equipWeapon(
      weapon: weapon,
      ownerId: widget.currentOwnerId,
    );

    final updated = await PlayerStorage.getPlayer();
    if (updated != null) {
      debugPrint('🎯 装备后：extraHp=${updated.extraHp}, extraAtk=${updated.extraAtk}, extraDef=${updated.extraDef}');
    }
  }

  Future<void> _unequipWeapon(Weapon weapon) async {
    await WeaponsStorage.unequipWeapon(weapon);

    final updated = await PlayerStorage.getPlayer();
    if (updated != null) {
      debugPrint('🧹 卸下后：extraHp=${updated.extraHp}, extraAtk=${updated.extraAtk}, extraDef=${updated.extraDef}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF9F5E3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.all(16),
        child: _weapons.isEmpty
            ? const Center(
          child: Text(
            '手中无兵，何谈修道？',
            style: TextStyle(color: Colors.black54),
          ),
        )
            : ListView.separated(
          itemCount: _weapons.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final weapon = _weapons[index];
            final isEquipped = weapon.equippedById == widget.currentOwnerId;

            return InkWell(
              onTap: () async {
                if (!isEquipped) {
                  await _equipWeapon(weapon);
                  widget.onEquipSelected(weapon);
                  widget.onChanged?.call();
                  _loadWeapons();
                }
              },
              child: Row(
                children: [
                  Image.asset(
                    weapon.iconPath,
                    width: 42,
                    height: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weapon.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          weapon.attackBoost > 0
                              ? '攻击 +${weapon.attackBoost}%'
                              : weapon.defenseBoost > 0
                              ? '防御 +${weapon.defenseBoost}%'
                              : '气血 +${weapon.hpBoost}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        if (isEquipped)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✅ 已装备',
                              style: TextStyle(color: Colors.green, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isEquipped)
                    GestureDetector(
                      onTap: () async {
                        await _unequipWeapon(weapon);
                        widget.onChanged?.call();
                        _loadWeapons();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '卸下',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
