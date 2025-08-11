import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/weapon.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/weapons_storage.dart';
import '../components/equip_slot.dart';

class PlayerEquipDialog extends StatefulWidget {
  final VoidCallback? onChanged;

  const PlayerEquipDialog({super.key, this.onChanged});

  @override
  State<PlayerEquipDialog> createState() => _PlayerEquipDialogState();
}

class _PlayerEquipDialogState extends State<PlayerEquipDialog> {
  Weapon? weapon;
  Weapon? armor;
  Weapon? accessory;
  List<Weapon> all = [];

  String playerId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final player = await PlayerStorage.getPlayer();
    if (player == null) return;
    playerId = player.id;
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final w = await WeaponsStorage.loadSortedByTimeDesc();
    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(playerId);
    setState(() {
      all = w;
      weapon = equipped.firstWhereOrNull((e) => e.type == 'weapon');
      armor = equipped.firstWhereOrNull((e) => e.type == 'armor');
      accessory = equipped.firstWhereOrNull((e) => e.type == 'accessory');
    });
  }

  void _openEquipTypeDialog(String type) {
    final list = all.where((w) =>
    w.type == type && (w.equippedById == null || w.equippedById == playerId)
    ).toList();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 420),
          padding: const EdgeInsets.all(16),
          child: list.isEmpty
              ? const Center(
            child: Text(
              '暂无可用装备',
              style: TextStyle(color: Colors.black54),
            ),
          )
              : ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              final item = list[i];
              final isEquipped = item.equippedById == playerId;
              return InkWell(
                onTap: isEquipped
                    ? null
                    : () async {
                  await _equip(item);
                  widget.onChanged?.call();
                },
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(item.iconPath, width: 42, height: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(fontSize: 13, color: Colors.black)),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _buildAttrText(item),
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ),
                            if (isEquipped)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF82D16F),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: const Text('✅ 已装备',
                                    style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                      if (isEquipped)
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () async {
                              await _unequip(item);
                              widget.onChanged?.call();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Text('卸下',
                                  style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _equip(Weapon w) async {
    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(playerId);
    for (final e in equipped) {
      if (e.type == w.type && e.key != w.key) {
        await WeaponsStorage.unequipWeapon(e);
      }
    }
    await WeaponsStorage.equipWeapon(weapon: w, ownerId: playerId);
    widget.onChanged?.call();
    await _loadAll();
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Future<void> _unequip(Weapon w) async {
    await WeaponsStorage.unequipWeapon(w);
    widget.onChanged?.call();
    await _loadAll();
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Widget buildSlot(String type, Weapon? weapon) {
    return EquipSlot(
      equipped: weapon,
      isEquipped: weapon != null && weapon.equippedById == playerId,
      onTap: () => _openEquipTypeDialog(type),
      onUnequip: weapon != null ? () => _unequip(weapon) : null,
      type: type,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FittedBox( // 自动等比缩小以适配可用宽度
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildSlot('accessory', accessory),
            const SizedBox(width: 12),
            buildSlot('weapon', weapon),
            const SizedBox(width: 12),
            buildSlot('armor', armor),
          ],
        ),
      ),
    );
  }
}

/// 属性文本
String _buildAttrText(Weapon w) {
  switch (w.type) {
    case 'weapon':
      return '攻击 +${w.attackBoost}%';
    case 'armor':
      return '防御 +${w.defenseBoost}%';
    case 'accessory':
      return '气血 +${w.hpBoost}%';
    default:
      return '';
  }
}
