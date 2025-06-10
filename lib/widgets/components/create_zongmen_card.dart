import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/zongmen_name_pool.dart'; // 🎲 getRandomZongmenName()
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart'; // 🔐 updateField()

class CreateZongmenCard extends StatefulWidget {
  final void Function(String name) onConfirm;

  const CreateZongmenCard({super.key, required this.onConfirm});

  @override
  State<CreateZongmenCard> createState() => _CreateZongmenCardState();
}

class _CreateZongmenCardState extends State<CreateZongmenCard> {
  String name = '';
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5E3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '创建你的宗门',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'ZcoolCangEr',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (val) => name = val,
              decoration: InputDecoration(
                hintText: '请输入宗门名称',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Text('🎲', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    final generated = getRandomZongmenName();
                    _controller.text = generated;
                    name = generated;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final trimmed = name.trim();
                final nameWithoutSpaces = trimmed.replaceAll(' ', '');

                final chineseOnly = RegExp(r'^[\u4e00-\u9fa5]+$');

                if (nameWithoutSpaces.isEmpty) {
                  _showError('宗门名称不能为空');
                  return;
                }
                if (!chineseOnly.hasMatch(nameWithoutSpaces)) {
                  _showError('只能使用中文字符');
                  return;
                }
                if (nameWithoutSpaces.length > 7) {
                  _showError('宗门名称最多7个字');
                  return;
                }

                // ✅ 更新职业
                await PlayerStorage.updateField('career', '$nameWithoutSpaces宗主');

                widget.onConfirm(nameWithoutSpaces);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '创建宗门',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'ZcoolCangEr')),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 2),
    ));
  }
}
