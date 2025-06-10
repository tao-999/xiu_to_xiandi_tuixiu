// lib/data/sect_task_data.dart

import 'package:uuid/uuid.dart';
import '../models/sect_task.dart';

final _uuid = Uuid();

/// 各类型任务的「模板」，不含 id，创建时再生成唯一 id
class SectTaskTemplate {
  final TaskType type;
  final String description;
  final int sectExp;
  final Map<String, int> extras;

  const SectTaskTemplate({
    required this.type,
    required this.description,
    required this.sectExp,
    this.extras = const {},
  });
}

/// 按类型分组的任务模板列表，想加新任务就直接在对应 List 里添加
const List<SectTaskTemplate> gatheringTemplates = [
  SectTaskTemplate(
    type: TaskType.gathering,
    description: '到九绮宫外采集灵谷草 x10',
    sectExp: 50,
    extras: {'spiritStoneLow': 200, 'reputation': 10},
  ),
  // … 加更多采集类任务
];

const List<SectTaskTemplate> combatTemplates = [
  SectTaskTemplate(
    type: TaskType.combat,
    description: '剿灭附近山野妖兽 5 只',
    sectExp: 80,
    extras: {'spiritStoneMid': 150},
  ),
  // … 加更多战斗类任务
];

const List<SectTaskTemplate> escortTemplates = [
  SectTaskTemplate(
    type: TaskType.escort,
    description: '护送门人安全往返昆仑山',
    sectExp: 60,
    extras: {'reputation': 15, 'pill_初级补元丹': 1},
  ),
  // … 加更多护送类任务
];

const List<SectTaskTemplate> explorationTemplates = [
  SectTaskTemplate(
    type: TaskType.exploration,
    description: '探索野外遗迹残卷 1 份',
    sectExp: 70,
    extras: {'skill_入门吐纳功': 1},
  ),
  // … 加更多探索类任务
];

const List<SectTaskTemplate> diplomacyTemplates = [
  SectTaskTemplate(
    type: TaskType.diplomacy,
    description: '与邻近派系商谈功法交流',
    sectExp: 40,
    extras: {'reputation': 20},
  ),
  // … 加更多外交类任务
];

/// 合并所有类型模板，方便外部引用
final Map<TaskType, List<SectTaskTemplate>> allTaskTemplates = {
  TaskType.gathering: gatheringTemplates,
  TaskType.combat: combatTemplates,
  TaskType.escort: escortTemplates,
  TaskType.exploration: explorationTemplates,
  TaskType.diplomacy: diplomacyTemplates,
};

/// 根据模板随机取一个任务，生成带 id 的 SectTask
SectTask createTaskFromTemplate(SectTaskTemplate tpl) {
  return SectTask(
    id: _uuid.v4(),
    type: tpl.type,
    description: tpl.description,
    sectExp: tpl.sectExp,
    extras: tpl.extras,
  );
}
