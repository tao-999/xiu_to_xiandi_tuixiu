// 📂 lib/widgets/components/reset_player_button.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiu_to_xiandi_tuixiu/pages/page_create_role.dart';
import 'package:xiu_to_xiandi_tuixiu/services/cultivation_tracker.dart';

import '../../services/maze_storage.dart';

class ResetPlayerButton extends StatelessWidget {
  const ResetPlayerButton({super.key});

  Future<void> _resetPlayer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定要重置角色吗？'),
        content: const Text('该操作将清空所有修为、信息和存档，无法恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      MazeStorage.clearAllMazeData(); // 如果你写了这种方法，就一起调用
      CultivationTracker.stopTick();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreateRolePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        tooltip: '清空角色数据',
        child: const Icon(Icons.delete_forever),
        onPressed: () => _resetPlayer(context),
      ),
    );
  }
}
