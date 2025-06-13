import 'package:flutter/material.dart';

class RefineMaterialSelector extends StatefulWidget {
  const RefineMaterialSelector({super.key});

  @override
  State<RefineMaterialSelector> createState() => _RefineMaterialSelectorState();
}

class _RefineMaterialSelectorState extends State<RefineMaterialSelector> {
  final List<String> _selectedMaterials = [];

  // 假数据：后续替换为真实配置
  final List<String> _allMaterials = [
    '玄铁碎片',
    '赤阳晶',
    '地脉石',
    '灵纹铜',
    '万年寒铁',
    '焚天砂',
  ];

  void _showMaterialDialog() async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFF7E5),
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择炼器材料',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'ZcoolCangEr',
                  color: Color(0xFF4E342E),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _allMaterials.map((name) {
                  final selected = _selectedMaterials.contains(name);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedMaterials.remove(name);
                        } else {
                          _selectedMaterials.add(name);
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Chip(
                      label: Text(name),
                      backgroundColor: selected ? Colors.greenAccent : Colors.grey[300],
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.grey[800],
                        fontFamily: 'ZcoolCangEr',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeMaterial(String name) {
    setState(() {
      _selectedMaterials.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🪵 炼器材料',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'ZcoolCangEr',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedMaterials.map(
                  (m) => Chip(
                label: Text(
                  m,
                  style: const TextStyle(fontFamily: 'ZcoolCangEr'),
                ),
                backgroundColor: Colors.brown[200],
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeMaterial(m),
              ),
            ),
            GestureDetector(
              onTap: _showMaterialDialog,
              child: Chip(
                label: const Text('＋ 添加材料'),
                backgroundColor: Colors.white24,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ZcoolCangEr',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
