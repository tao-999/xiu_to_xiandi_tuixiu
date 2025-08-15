// 📂 lib/widgets/components/gongfa_dual_equip_panel.dart
import 'package:flutter/material.dart';

import '../../models/gongfa.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../services/player_storage.dart';
import '../../services/gongfa_equip_service.dart';

/// 🔥 双槽合一：一个组件同时管理【速度】和【攻击技能】两种功法的装备/卸下
/// - 左槽：速度功法（GongfaType.movement）
/// - 右槽：攻击技能功法（GongfaType.attack）
/// - 点击槽位：弹出对应选择框；长按槽位：卸下
class GongfaDualEquipPanel extends StatefulWidget {
  final VoidCallback? onChanged;
  final double size;     // 每个槽位方块尺寸
  final double spacing;  // 槽位间距

  const GongfaDualEquipPanel({
    super.key,
    this.onChanged,
    this.size = 40,
    this.spacing = 8,
  });

  @override
  State<GongfaDualEquipPanel> createState() => _GongfaDualEquipPanelState();
}

class _GongfaDualEquipPanelState extends State<GongfaDualEquipPanel> {
  String _playerId = '';

  // —— 已装备 —— //
  Gongfa? _equippedMovement;
  Gongfa? _equippedAttack;

  // —— 可用列表 —— //
  List<Gongfa> _availableMovement = [];
  List<Gongfa> _availableAttack = [];

  String _img(String p) {
    const prefix = 'assets/images/';
    return p.startsWith(prefix) ? p : '$prefix$p';
  }

  // === 辅助：读取 atkBoost 并转百分比文本（1.18 -> +118%） ===
  double _getAtkBoost(Gongfa g) {
    try {
      final dyn = g as dynamic;
      final v = dyn.atkBoost;
      if (v is num) return v.toDouble();
    } catch (_) {}
    return 0.0;
  }

  String _atkBoostPercentText(Gongfa g) {
    final pct = (_getAtkBoost(g) * 100);
    // 显示为整数百分比
    return '+${pct.toStringAsFixed(0)}%';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = await PlayerStorage.getPlayer();
    if (p == null) return;
    _playerId = p.id;
    await Future.wait([_loadEquipped(), _loadAvailable()]);
  }

  Future<void> _loadEquipped() async {
    final m = await GongfaEquipService.loadEquipped(
      slot: GongfaEquipService.movementSlot,
      type: GongfaType.movement,
    );
    final a = await GongfaEquipService.loadEquipped(
      slot: GongfaEquipService.attackSlot,
      type: GongfaType.attack,
    );
    _equippedMovement = m;
    _equippedAttack = a;

    if (mounted) setState(() {});
  }

  Future<void> _loadAvailable() async {
    final all = await GongfaCollectedStorage.getAllGongfa();

    _availableMovement = all
        .where((g) => g.type == GongfaType.movement && g.count > 0)
        .toList()
      ..sort((a, b) {
        // 速度：等级降序 -> 提速百分比降序 -> 名称升序
        final lv = b.level.compareTo(a.level);
        if (lv != 0) return lv;
        final spd = b.moveSpeedBoost.compareTo(a.moveSpeedBoost);
        if (spd != 0) return spd;
        return a.name.compareTo(b.name);
      });

    _availableAttack = all
        .where((g) => g.type == GongfaType.attack && g.count > 0)
        .toList()
      ..sort((a, b) {
        // 攻击：等级降序 -> 名称升序
        final lv = b.level.compareTo(a.level);
        if (lv != 0) return lv;
        return a.name.compareTo(b.name);
      });

    if (mounted) setState(() {});
  }

  // —— 装备 / 卸下 —— //
  Future<void> _equipMovement(Gongfa g) async {
    await GongfaEquipService.equip(slot: GongfaEquipService.movementSlot, gongfa: g);
    widget.onChanged?.call();
    await _loadEquipped();
    await _loadAvailable();
    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Future<void> _equipAttack(Gongfa g) async {
    await GongfaEquipService.equip(slot: GongfaEquipService.attackSlot, gongfa: g);
    widget.onChanged?.call();
    await _loadEquipped();
    await _loadAvailable();
    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Future<void> _unequipMovement() async {
    await GongfaEquipService.unequip(GongfaEquipService.movementSlot);
    widget.onChanged?.call();
    await _loadEquipped();
    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Future<void> _unequipAttack() async {
    await GongfaEquipService.unequip(GongfaEquipService.attackSlot);
    widget.onChanged?.call();
    await _loadEquipped();
    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();
  }

  // —— 弹框：根据槽位展示不同列表 —— //
  void _openDialog({required bool isMovement}) {
    final items = isMovement ? _availableMovement : _availableAttack;
    final equipped = isMovement ? _equippedMovement : _equippedAttack;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: items.isEmpty
                ? Center(
              child: Text(
                isMovement ? '暂无可用速度功法' : '暂无可用攻击技能功法',
                style: const TextStyle(color: Colors.black54),
              ),
            )
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final item = items[i];
                final isEquipped = (equipped?.id == item.id);
                final atkText = _atkBoostPercentText(item);

                return InkWell(
                  onTap: isEquipped
                      ? null
                      : () => isMovement ? _equipMovement(item) : _equipAttack(item),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(_img(item.iconPath), width: 42, height: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(fontSize: 13, color: Colors.black)),
                            const SizedBox(height: 2),
                            Text(
                              isMovement
                                  ? '移动速度 +${(item.moveSpeedBoost * 100).toStringAsFixed(0)}%（Lv.${item.level}）'
                                  : '主动技能 伤害${atkText}（Lv.${item.level}）',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (isEquipped)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFF82D16F),
                          child: const Text('✅ 已装备',
                              style: TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      else
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: Colors.black87, width: 1),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () =>
                          isMovement ? _equipMovement(item) : _equipAttack(item),
                          child: const Text('装备', style: TextStyle(fontSize: 12)),
                        ),
                      if (isEquipped)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              side: const BorderSide(color: Colors.red, width: 1),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: isMovement ? _unequipMovement : _unequipAttack,
                            child: const Text('卸下',
                                style: TextStyle(fontSize: 12, color: Colors.red)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // —— 槽位小方块 —— //
  Widget _slot({
    required String label,
    required Gongfa? equipped,
    required VoidCallback onTap,
    required VoidCallback onLongPressRemove,
    required Widget Function(Gongfa g) cornerBuilder,
  }) {
    final size = widget.size;
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (equipped != null) onLongPressRemove();
      },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: equipped == null
            ? Text(label, style: const TextStyle(fontSize: 12, color: Colors.black))
            : Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(_img(equipped.iconPath), fit: BoxFit.contain),
            ),
            Positioned(right: 1, bottom: 1, child: cornerBuilder(equipped)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左：速度槽
        _slot(
          label: '速度',
          equipped: _equippedMovement,
          onTap: () => _openDialog(isMovement: true),
          onLongPressRemove: _unequipMovement,
          cornerBuilder: (g) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            color: const Color(0xCC000000),
            child: Text(
              '+${(g.moveSpeedBoost * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 9, color: Colors.white, height: 1),
            ),
          ),
        ),
        SizedBox(width: widget.spacing),
        // 右：攻击槽
        _slot(
          label: '技能',
          equipped: _equippedAttack,
          onTap: () => _openDialog(isMovement: false),
          onLongPressRemove: _unequipAttack,
          cornerBuilder: (g) {
            final atkText = _atkBoostPercentText(g); // 伤害倍率百分比
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              color: const Color(0xCC000000),
              child: Text(
                'Lv.${g.level} · $atkText',
                style: const TextStyle(fontSize: 9, color: Colors.white, height: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}
