// lib/services/task_dispatcher.dart

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sect_task.dart';
import '../data/sect_task_data.dart';

class TaskDispatcher {
  static const String _tasksKey = 'sect_tasks';
  static const String _lastRefreshKey = 'sect_tasks_last_refresh';
  static const Duration _refreshInterval = Duration(hours: 12);

  /// 加载当前可派遣任务列表，会根据刷新间隔自动生成或读取缓存
  static Future<List<SectTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastRefreshKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    List<SectTask> tasks;

    // 判断是否需要刷新
    if (nowMs - lastMs >= _refreshInterval.inMilliseconds) {
      tasks = _generateTasks();
      await prefs.setString(
        _tasksKey,
        jsonEncode(tasks.map((t) => t.toMap()).toList()),
      );
      await prefs.setInt(_lastRefreshKey, nowMs);
    } else {
      final raw = prefs.getString(_tasksKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        tasks = list
            .map((m) => SectTask.fromMap(m as Map<String, dynamic>))
            .toList();
      } else {
        tasks = _generateTasks();
        await prefs.setString(
          _tasksKey,
          jsonEncode(tasks.map((t) => t.toMap()).toList()),
        );
        await prefs.setInt(_lastRefreshKey, nowMs);
      }
    }

    return tasks;
  }

  /// 生成一组随机任务，每种类型至少一个，模板来源于 sect_task_data.dart
  static List<SectTask> _generateTasks() {
    final rand = Random();
    final tasks = <SectTask>[];

    // 遍历每种任务类型，从对应模板列表随机抽取一个
    for (var type in TaskType.values) {
      final pool = allTaskTemplates[type];
      if (pool == null || pool.isEmpty) continue;
      final tpl = pool[rand.nextInt(pool.length)];
      tasks.add(createTaskFromTemplate(tpl));
    }

    return tasks;
  }

  /// 手动清除缓存，下次 loadTasks 会强制刷新
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_lastRefreshKey);
  }
}
