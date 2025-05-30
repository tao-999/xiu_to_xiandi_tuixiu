// 📦 widgets/dialogs/disciple_list_dialog.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';

class DiscipleListDialog extends StatelessWidget {
  final List<Disciple> disciples;

  const DiscipleListDialog({super.key, required this.disciples});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📜 已招募修士',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SizedBox(
              height: 400,
              child: disciples.isEmpty
                  ? const Center(child: Text('暂无记录，快去招募吧～'))
                  : ListView.builder(
                itemCount: disciples.length,
                itemBuilder: (_, index) {
                  final reversed = disciples.reversed.toList();
                  final d = reversed[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: d.imagePath.isNotEmpty
                          ? AssetImage(d.imagePath)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: d.imagePath.isEmpty
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    title: Text(d.name),
                    subtitle: Text('资质: ${d.aptitude}｜年龄: ${d.age}'),
                    trailing: Text(d.gender == 'female' ? '♀️' : '♂️'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
