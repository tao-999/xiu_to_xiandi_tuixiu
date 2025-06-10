// lib/widgets/components/sect_task_list.dart

import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/sect_task.dart';

typedef DispatchCallback = void Function(SectTask task);

class SectTaskList extends StatelessWidget {
  final List<SectTask> tasks;
  final DispatchCallback onDispatch;

  const SectTaskList({
    Key? key,
    required this.tasks,
    required this.onDispatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('暂无可派遣任务，歇会儿吧~'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white24),
      itemBuilder: (context, index) {
        final t = tasks[index];
        return ListTile(
          leading: _buildTypeIcon(t.type),
          title: Text(
            t.description,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '宗门经验 ×${t.sectExp}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (t.extras.isNotEmpty)
                Text(
                  '附加奖励：' +
                      t.extras.entries
                          .map((e) => '${e.key}×${e.value}')
                          .join('，'),
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            child: const Text('派遣'),
            onPressed: () => onDispatch(t),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.gathering:
        return const Icon(Icons.grass, color: Colors.green);
      case TaskType.combat:
        return const Icon(Icons.gavel, color: Colors.red);
      case TaskType.escort:
        return const Icon(Icons.local_shipping, color: Colors.blue);
      case TaskType.exploration:
        return const Icon(Icons.explore, color: Colors.orange);
      case TaskType.diplomacy:
        return const Icon(Icons.handshake, color: Colors.purple);
    }
  }
}
