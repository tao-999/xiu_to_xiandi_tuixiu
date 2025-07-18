import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/weapon.dart';

class EquipSlot extends StatelessWidget {
  final Weapon? equipped;
  final bool isEquipped;
  final VoidCallback onTap;
  final VoidCallback? onUnequip;
  final String type; // 'weapon', 'armor', 'accessory'

  const EquipSlot({
    super.key,
    required this.equipped,
    required this.isEquipped,
    required this.onTap,
    this.onUnequip,
    required this.type,
  });

  String getBoostLabel(Weapon w) {
    if (w.attackBoost > 0) return '攻击 +${w.attackBoost}%';
    if (w.defenseBoost > 0) return '防御 +${w.defenseBoost}%';
    if (w.hpBoost > 0) return '气血 +${w.hpBoost}%';
    return '无加成';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: equipped == null
          ? InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Text(
              type == 'weapon'
                  ? '武器'
                  : type == 'armor'
                  ? '服饰'
                  : type == 'accessory'
                  ? '饰品'
                  : '装备',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      )
          : InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            equipped!.iconPath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
