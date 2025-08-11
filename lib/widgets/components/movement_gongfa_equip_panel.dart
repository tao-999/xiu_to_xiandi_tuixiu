// 📂 lib/widgets/components/movement_gongfa_equip_panel.dart
import 'package:flutter/material.dart';

import '../../models/gongfa.dart';
import '../../services/gongfa_collected_storage.dart';
import '../../services/gongfa_equip_storage.dart';
import '../../services/player_storage.dart';

/// 速度功法装备面板：一个“速度”槽位，点击弹出速度功法选择/卸下对话框。
/// 数据来源：GongfaCollectedStorage（只展示玩家已获得的速度功法）
class MovementGongfaEquipPanel extends StatefulWidget {
  final VoidCallback? onChanged;

  const MovementGongfaEquipPanel({super.key, this.onChanged});

  @override
  State<MovementGongfaEquipPanel> createState() => _MovementGongfaEquipPanelState();
}

class _MovementGongfaEquipPanelState extends State<MovementGongfaEquipPanel> {
  String _playerId = '';
  Gongfa? _equipped;
  List<Gongfa> _available = [];

  String _img(String p) {
    const prefix = 'assets/images/';
    return p.startsWith(prefix) ? p : '$prefix$p';
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
    _equipped = await GongfaEquipStorage.loadEquippedMovementBy(_playerId);
    if (mounted) setState(() {});
  }

  Future<void> _loadAvailable() async {
    final all = await GongfaCollectedStorage.getAllGongfa();
    _available = all
        .where((g) => g.type == GongfaType.movement && g.count > 0)
        .toList()
      ..sort((a, b) {
        final lv = b.level.compareTo(a.level);
        if (lv != 0) return lv;
        final spd = b.moveSpeedBoost.compareTo(a.moveSpeedBoost);
        if (spd != 0) return spd;
        return a.name.compareTo(b.name);
      });
    if (mounted) setState(() {});
  }

  Future<void> _equip(Gongfa g) async {
    await GongfaEquipStorage.equipMovement(ownerId: _playerId, gongfa: g);
    widget.onChanged?.call();
    await _loadEquipped();
    await _loadAvailable();
    if (context.mounted && Navigator.canPop(context)) Navigator.of(context).pop();
  }

  Future<void> _unequip() async {
    await GongfaEquipStorage.unequipMovement(_playerId);
    widget.onChanged?.call();
    await _loadEquipped();
    if (context.mounted && Navigator.canPop(context)) Navigator.of(context).pop();
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF9F5E3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _available.isEmpty
                ? const Center(child: Text('暂无可用速度功法', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
              itemCount: _available.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final item = _available[i];
                final isEquipped =
                    _equipped?.id == item.id; // id 唯一即可判断

                return InkWell(
                  onTap: isEquipped ? null : () => _equip(item),
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
                              _attrText(item),
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
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _equip(item),
                          child: const Text('装备', style: TextStyle(fontSize: 12)),
                        ),
                      if (isEquipped)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: Colors.red, width: 1),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _unequip,
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

  @override
  Widget build(BuildContext context) {
    // ✅ 槽位：已装备 → 显示图标；未装备 → “速度”
    return GestureDetector(
      onTap: _openDialog,
      onLongPress: () {
        if (_equipped != null) _unequip();
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: _equipped == null
            ? const Text('速度', style: TextStyle(fontSize: 12, color: Colors.black))
            : Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                _img(_equipped!.iconPath),
                fit: BoxFit.contain,
              ),
            ),
            // 右下角显示速度百分比
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                color: const Color(0xCC000000),
                child: Text(
                  '+${(_equipped!.moveSpeedBoost * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 9, color: Colors.white, height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _attrText(Gongfa g) {
    final spdPct = (g.moveSpeedBoost * 100).toStringAsFixed(0);
    return '移动速度 +$spdPct%（Lv.${g.level}）';
  }
}
