import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/disciple_registry.dart';

/// ✅ 获取玩家已拥有的弟子资质（从图鉴）
Future<Set<int>> _loadOwnedAptitudes() async {
  return await DiscipleRegistry.loadOwned();
}

/// ✅ 小头像组件，右下角打钩表示已拥有
Widget _buildDiscipleAvatar(String aptitude, Set<int> ownedAptitudes) {
  final int value = int.parse(aptitude);
  final bool owned = ownedAptitudes.contains(value);

  return Stack(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/disciples/$aptitude.png'),
            fit: BoxFit.contain,
            alignment: Alignment.topCenter, // ✅ 显示上半身
          ),
        ),
      ),
      if (owned)
        const Positioned(
          bottom: 0,
          right: 0,
          child: Icon(Icons.check_circle, color: Colors.white70, size: 14),
        ),
    ],
  );
}

/// ✅ 每一组资质段落
Widget _buildSection(String title, Set<int> ownedAptitudes, int start, int end) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = start; i <= end; i++)
            _buildDiscipleAvatar(i.toString(), ownedAptitudes),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}

/// ✅ 弹出预览弹窗（已整合显示+状态）
Future<void> showDisciplePreviewDialog(BuildContext context) async {
  final ownedAptitudes = await _loadOwnedAptitudes();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1D1A17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('元婴天赋', ownedAptitudes, 31, 40),
              _buildSection('化神天赋', ownedAptitudes, 41, 50),
              _buildSection('炼虚天赋', ownedAptitudes, 51, 60),
              _buildSection('合体天赋', ownedAptitudes, 61, 70),
              _buildSection('大乘天赋', ownedAptitudes, 71, 80),
              _buildSection('渡劫天赋', ownedAptitudes, 81, 90),
              _buildSection('飞升天赋', ownedAptitudes, 91, 100),
            ],
          ),
        ),
      );
    },
  );
}
