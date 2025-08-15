import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/gongfa.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_collected_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/gongfa_equip_service.dart';

class GongfaFusionDialog extends StatefulWidget {
  final VoidCallback? onChanged;
  const GongfaFusionDialog({super.key, this.onChanged});

  @override
  State<GongfaFusionDialog> createState() => _GongfaFusionDialogState();
}

class _GongfaFusionDialogState extends State<GongfaFusionDialog> {
  static const int _need = 4;

  final List<_Item> _items = [];
  final Set<String> _selected = {};
  String? _lockKey;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _asset(String p) => p.startsWith('assets/') ? p : 'assets/images/$p';
  String _canonKey(Gongfa g) => '${g.name}|${g.level}|${g.type.index}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _items.clear();
      _selected.clear();
      _lockKey = null;
    });

    final all = await GongfaCollectedStorage.getAllGongfa();

    final eqMove = await GongfaEquipService.loadEquipped(
        slot: GongfaEquipService.movementSlot, type: GongfaType.movement);
    final eqAtk = await GongfaEquipService.loadEquipped(
        slot: GongfaEquipService.attackSlot, type: GongfaType.attack);

    final Map<String, int> countBy = {};
    final Map<String, Gongfa> sampleBy = {};
    for (final g in all) {
      final k = _canonKey(g);
      countBy[k] = (countBy[k] ?? 0) + (g.count > 0 ? g.count : 0);
      sampleBy[k] = g;
    }

    void dec(Gongfa? e) {
      if (e == null) return;
      final k = _canonKey(e);
      if ((countBy[k] ?? 0) > 0) countBy[k] = countBy[k]! - 1;
    }
    dec(eqMove);
    dec(eqAtk);

    countBy.removeWhere((_, n) => n <= 0);
    for (final entry in countBy.entries) {
      final k = entry.key;
      final n = entry.value;
      final seed = sampleBy[k]!;
      for (int i = 0; i < n; i++) {
        _items.add(_Item(uid: '$k#$i', lockKey: k, seed: seed));
      }
    }

    setState(() => _loading = false);
  }

  bool _disabled(_Item it) => _lockKey != null && it.lockKey != _lockKey;

  void _toggle(_Item it) {
    if (_disabled(it)) return;
    setState(() {
      if (_selected.contains(it.uid)) {
        _selected.remove(it.uid);
        if (_selected.isEmpty) _lockKey = null;
      } else {
        _lockKey ??= it.lockKey;
        if (_selected.length < _need) {
          _selected.add(it.uid);
        }
      }
    });
  }

  Future<void> _combine() async {
    if (_selected.length != _need) return;

    // 任意一张作为模板
    final any = _items.firstWhere((e) => _selected.contains(e.uid));
    final g0 = any.seed;

    // —— 扣库存（该组 4 本）——
    final all = await GongfaCollectedStorage.getAllGongfa();
    int total = 0;
    final List<Gongfa> sameGroup = [];
    for (final g in all) {
      if (_canonKey(g) == any.lockKey) {
        total += g.count;
        sameGroup.add(g);
      }
    }
    for (final g in sameGroup) {
      await GongfaCollectedStorage.deleteGongfaByIdAndLevel(g.id, g.level);
    }
    final remain = (total - _need).clamp(0, 1 << 30);
    if (remain > 0) {
      await GongfaCollectedStorage.addGongfa(g0.copyWith(count: remain));
    }

    // —— 产出：同名同类型 Lv+1，并按类型附加成长 —— //
    double atkBoost = g0.atkBoost;
    double moveBoost = g0.moveSpeedBoost;
    double atkSpeed  = g0.attackSpeed;

    if (g0.type == GongfaType.attack) {
      atkBoost = atkBoost + 0.05;
      atkSpeed = (atkSpeed - 0.05);
      if (atkSpeed < 0.2) atkSpeed = 0.2; // 不低于 0.2
    } else if (g0.type == GongfaType.movement) {
      moveBoost = moveBoost + 0.05;
    }

    final out = Gongfa(
      id: g0.id,
      name: g0.name,
      level: g0.level + 1,
      type: g0.type,
      description: g0.description,
      atkBoost: atkBoost,
      defBoost: g0.defBoost,
      hpBoost: g0.hpBoost,
      iconPath: g0.iconPath,
      isLearned: false,
      acquiredAt: DateTime.now(),
      count: 1,
      moveSpeedBoost: moveBoost,
      attackSpeed: atkSpeed,
    );

    await GongfaCollectedStorage.addGongfa(out);

    await _load();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final canCombine = _selected.length == _need;

    return Dialog(
      backgroundColor: const Color(0xFFF9F5E3),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_fix_high, size: 16, color: Colors.black87),
                  SizedBox(width: 6),
                  Text('功法合成',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                  child: Text('没有可用于合成的功法（未被装备占用）',
                      style: TextStyle(color: Colors.black54)),
                )
                    : GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    final g = it.seed;
                    final picked = _selected.contains(it.uid);
                    final disabled = _disabled(it);

                    return GestureDetector(
                      onTap: () => _toggle(it),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: picked
                                ? const Color(0xFFDB6F18)
                                : Colors.black87,
                            width: picked ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      _asset(g.iconPath),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    g.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black87),
                                  ),
                                  Text('Lv.${g.level}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black54)),
                                ],
                              ),
                            ),
                            if (disabled)
                              Container(
                                color: Colors.black.withOpacity(0.55),
                              ),
                            if (picked)
                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Color(0xFFDB6F18),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _lockKey == null
                          ? '选择任意 1 张后，仅可继续选择【同名字+同等级+同类型】的卡；再次点击可取消。'
                          : '正在合成：${_lockKey!.split("|")[0]}（Lv.${_lockKey!.split("|")[1]}）  已选 ${_selected.length}/$_need',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: canCombine ? _combine : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      canCombine ? const Color(0xFFDB6F18) : Colors.black26,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('合成'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  _Item({required this.uid, required this.lockKey, required this.seed});
  final String uid;
  final String lockKey; // name|level|typeIndex
  final Gongfa seed;
}
