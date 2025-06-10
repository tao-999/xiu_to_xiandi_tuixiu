// lib/models/sect_task.dart

import 'package:meta/meta.dart';

/// 任务类型枚举
enum TaskType {
  gathering,   // 采集
  combat,      // 战斗
  escort,      // 护送
  exploration, // 探索
  diplomacy,   // 外交
}

@immutable
class SectTask {
  final String id;
  final TaskType type;
  final String description;
  final int sectExp;               // 宗门经验
  final Map<String, int> extras;   // 其他奖励

  const SectTask({
    required this.id,
    required this.type,
    required this.description,
    required this.sectExp,
    this.extras = const {},
  }) : assert(sectExp >= 0, 'sectExp 必须>=0');

  /// 序列化
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'description': description,
    'sectExp': sectExp,
    'extras': extras,
  };

  /// 反序列化：兼容老版 reward 格式
  factory SectTask.fromMap(Map<String, dynamic> map) {
    // 老格式：只有 reward 字段
    if (map.containsKey('reward')) {
      final raw = Map<String, dynamic>.from(map['reward'] as Map);
      // exp 对应 sectExp，其它都当 extras
      final sectExp = (raw['exp'] as int?) ?? 0;
      raw.remove('exp');
      final extras = raw.map((k, v) => MapEntry(k, v as int));
      return SectTask(
        id: map['id'] as String,
        type: TaskType.values[map['type'] as int],
        description: map['description'] as String,
        sectExp: sectExp,
        extras: extras,
      );
    }
    // 新格式：有 sectExp 和 extras
    final sectExp = (map['sectExp'] as int?) ?? 0;
    final extras = Map<String, int>.from(map['extras'] as Map? ?? {});
    return SectTask(
      id: map['id'] as String,
      type: TaskType.values[map['type'] as int],
      description: map['description'] as String,
      sectExp: sectExp,
      extras: extras,
    );
  }
}
