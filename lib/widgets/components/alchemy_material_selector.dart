import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/pill_blueprint.dart';
import 'package:xiu_to_xiandi_tuixiu/services/herb_material_service.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/common/toast_tip.dart';

class AlchemyMaterialSelector extends StatelessWidget {
  final PillBlueprint? selectedBlueprint;
  final List<String> selectedMaterials;
  final void Function(int index, String name) onMaterialSelected;
  final bool isDisabled; // ✅ 新增参数

  const AlchemyMaterialSelector({
    super.key,
    required this.selectedBlueprint,
    required this.selectedMaterials,
    required this.onMaterialSelected,
    this.isDisabled = false,
  });

  void _showMaterialDialog(BuildContext context, int index) async {
    final blueprint = selectedBlueprint;
    if (blueprint == null) {
      ToastTip.show(context, '先选择一个丹方！');
      return;
    }

    final herbs = HerbMaterialService.getMaterialsByBlueprint(
      blueprint.level,
      blueprint.type,
    );
    final inv = await HerbMaterialService.loadInventory();

    // 🧪 无库存处理
    final available = herbs.where((e) => (inv[e.name] ?? 0) > 0).toList();
    if (available.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFFFFF7E5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '材料都没有，您炼的是幻术丹吗？',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ),
      );
      return;
    }

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
            children: herbs.where((e) => (inv[e.name] ?? 0) > 0).map((herb) {
              final isSelected = selectedMaterials.contains(herb.name);
              final isCurrent = selectedMaterials.length > index &&
                  selectedMaterials[index] == herb.name;
              final count = inv[herb.name] ?? 0;

              return GestureDetector(
                onTap: () {
                  if (isSelected && !isCurrent) {
                    Navigator.pop(context);
                    ToastTip.show(context, '你已经选过这个材料了，不能重复使用～');
                    return;
                  }
                  Navigator.pop(context);
                  onMaterialSelected(index, herb.name);
                },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            herb.image,
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) => const Icon(Icons.grass),
                          ),
                          if (isCurrent)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${herb.name} × $count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final name = selectedMaterials.length > i ? selectedMaterials[i] : '';
        final herb = HerbMaterialService.getByName(name);

        final child = name.isEmpty
            ? Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.black.withOpacity(0.2),
          ),
          child: const Center(child: Icon(Icons.add, color: Colors.white)),
        )
            : Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 60,
          height: 60,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: Image.asset(
              herb?.image ?? '',
              fit: BoxFit.cover,
              width: 60,
              height: 60,
            ),
          ),
        );

        return GestureDetector(
          onTap: isDisabled ? null : () => _showMaterialDialog(context, i),
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0, // ✅ 禁用时半透明
            child: child,
          ),
        );
      }),
    );
  }
}
