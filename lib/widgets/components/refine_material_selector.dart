import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/refine_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/refine_material_service.dart';
import '../common/toast_tip.dart';

class RefineMaterialSelector extends StatefulWidget {
  final RefineBlueprint blueprint;
  final List<String> selectedMaterials;
  final void Function(int index, String name) onMaterialSelected;
  final bool isDisabled;

  const RefineMaterialSelector({
    super.key,
    required this.blueprint,
    required this.selectedMaterials,
    required this.onMaterialSelected,
    this.isDisabled = false,
  });

  @override
  State<RefineMaterialSelector> createState() => _RefineMaterialSelectorState();
}

class _RefineMaterialSelectorState extends State<RefineMaterialSelector> {
  Map<String, int> ownedMaterials = {};

  @override
  void initState() {
    super.initState();
    _loadOwnedMaterials();
  }

  Future<void> _loadOwnedMaterials() async {
    final inv = await RefineMaterialService.loadInventory();
    setState(() {
      ownedMaterials = inv..removeWhere((key, value) => value <= 0);
    });
  }

  void _selectMaterial(int index) async {
    if (widget.isDisabled) return;

    final Map<String, int> tempInventory = Map.from(ownedMaterials);

    for (final name in widget.selectedMaterials) {
      if (name.trim().isEmpty) continue;
      if (tempInventory.containsKey(name)) {
        tempInventory[name] = tempInventory[name]! - 1;
        if (tempInventory[name]! <= 0) {
          tempInventory.remove(name);
        }
      }
    }

    final usable = widget.blueprint.materials
        .where((name) => tempInventory.containsKey(name))
        .toList();

    // ✅ 如果一个都不能用，直接弹骚话
    if (usable.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFFFFF7E5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: const Text(
              '你身无分文，一块炼器材料都没有…\n还想炼器？先去搬砖吧。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.brown,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
          ),
        ),
      );
      return;
    }

    // ✅ 弹材料选择框
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: usable.map((name) {
              final mat = RefineMaterialService.getByName(name);
              final count = tempInventory[name] ?? 0;

              return GestureDetector(
                onTap: () {
                  final isDuplicate = widget.selectedMaterials
                      .asMap()
                      .entries
                      .any((entry) =>
                  entry.key != index && entry.value == name);

                  if (isDuplicate) {
                    Navigator.pop(context);
                    ToastTip.show(context, '你已经选过这个材料了，不能重复使用～');
                    return;
                  }

                  Navigator.pop(context);
                  widget.onMaterialSelected(index, name);
                },
                child: Container(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        mat?.image ?? '',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$name × $count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'ZcoolCangEr',
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        final isValid = i < widget.selectedMaterials.length &&
            widget.selectedMaterials[i].trim().isNotEmpty;

        final materialName = isValid ? widget.selectedMaterials[i] : null;
        final material = materialName != null
            ? RefineMaterialService.getByName(materialName)
            : null;

        return GestureDetector(
          onTap: () => _selectMaterial(i),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
              border: Border.all(
                color: widget.isDisabled ? Colors.grey : Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: material != null
                  ? Image.asset(
                material.image,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 20),
              )
                  : const Text(
                '＋',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
