import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/herb_material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/danfang_service.dart';

class AlchemyMaterialSelector extends StatelessWidget {
  const AlchemyMaterialSelector({super.key});

  void _showMaterialDialog(BuildContext context) async {
    final List<HerbMaterial> herbs = await DanfangService.loadHerbs();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF8DC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 300,
            height: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择材料',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: herbs.isEmpty
                      ? const Center(child: Text('你还没有任何草药~'))
                      : ListView.builder(
                    itemCount: herbs.length,
                    itemBuilder: (_, i) {
                      final herb = herbs[i];
                      return ListTile(
                        leading: Image.asset(
                          herb.imagePath,
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(Icons.grass),
                        ),
                        title: Text('${herb.name} ×${herb.quantity}'),
                        subtitle: Text(herb.description),
                        onTap: () {
                          // TODO: 选择逻辑（下阶段）
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (_) {
        return GestureDetector(
          onTap: () => _showMaterialDialog(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.black.withOpacity(0.2),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}
