// lib/pages/page_task_dispatch.dart
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/sect_task.dart';
import 'package:xiu_to_xiandi_tuixiu/services/task_dispatcher.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/sect_task_list.dart';

class TaskDispatchPage extends StatefulWidget {
  const TaskDispatchPage({Key? key}) : super(key: key);

  @override
  _TaskDispatchPageState createState() => _TaskDispatchPageState();
}

class _TaskDispatchPageState extends State<TaskDispatchPage> {
  late Future<List<SectTask>> _futureTasks;

  @override
  void initState() {
    super.initState();
    _futureTasks = TaskDispatcher.loadTasks();
  }

  void _refreshTasks() {
    setState(() {
      _futureTasks = TaskDispatcher.loadTasks();
    });
  }

  void _handleDispatch(SectTask task) {
    // TODO: 派遣逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已派遣任务：${task.description}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/zongmen_bg_task.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: FutureBuilder<List<SectTask>>(
                future: _futureTasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('加载任务失败：${snapshot.error}'));
                  }
                  return SectTaskList(
                    tasks: snapshot.data!,
                    onDispatch: _handleDispatch,
                  );
                },
              ),
            ),
            const BackButtonOverlay(),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: '手动刷新任务',
                onPressed: _refreshTasks,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
