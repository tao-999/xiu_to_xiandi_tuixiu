import 'pill.dart';
import 'technique.dart';
import 'disciple.dart';

class Zongmen {
  final String id;           // ✅ 唯一 ID，便于切换宗门或云存储
  String name;               // 宗门名称
  int level;                 // 宗门等级
  String founderName;        // 宗主（或创建者）
  String description;        // 宗门说明（比如“以丹入道、济世渡人”）
  String emblemPath;         // 宗门徽章贴图路径
  String specialization;     // 修炼方向（剑修、丹修、女修、御兽等）
  DateTime createdAt;        // 创建时间

  // 资源
  int spiritStoneLow;
  int spiritStoneMid;
  int spiritStoneHigh;
  int spiritStoneSupreme;

  // 子模块
  List<Pill> pills;
  List<Technique> techniques;
  List<Disciple> disciples;

  Zongmen({
    required this.id,
    required this.name,
    this.level = 1,
    required this.founderName,
    this.description = '',
    required this.emblemPath,
    this.specialization = '',
    DateTime? createdAt,
    this.spiritStoneLow = 0,
    this.spiritStoneMid = 0,
    this.spiritStoneHigh = 0,
    this.spiritStoneSupreme = 0,
    List<Pill>? pills,
    List<Technique>? techniques,
    List<Disciple>? disciples,
  })  : createdAt = createdAt ?? DateTime.now(),
        pills = pills ?? [],
        techniques = techniques ?? [],
        disciples = disciples ?? [];

  factory Zongmen.fromMap(Map<String, dynamic> map) {
    return Zongmen(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      founderName: map['founderName'],
      description: map['description'] ?? '',
      emblemPath: map['emblemPath'],
      specialization: map['specialization'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      spiritStoneLow: map['spiritStoneLow'] ?? 0,
      spiritStoneMid: map['spiritStoneMid'] ?? 0,
      spiritStoneHigh: map['spiritStoneHigh'] ?? 0,
      spiritStoneSupreme: map['spiritStoneSupreme'] ?? 0,
      pills: (map['pills'] as List? ?? []).map((e) => Pill.fromMap(e)).toList(),
      techniques: (map['techniques'] as List? ?? []).map((e) => Technique.fromMap(e)).toList(),
      disciples: (map['disciples'] as List? ?? []).map((e) => Disciple.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'founderName': founderName,
      'description': description,
      'emblemPath': emblemPath,
      'specialization': specialization,
      'createdAt': createdAt.toIso8601String(),
      'spiritStoneLow': spiritStoneLow,
      'spiritStoneMid': spiritStoneMid,
      'spiritStoneHigh': spiritStoneHigh,
      'spiritStoneSupreme': spiritStoneSupreme,
      'pills': pills.map((e) => e.toMap()).toList(),
      'techniques': techniques.map((e) => e.toMap()).toList(),
      'disciples': disciples.map((e) => e.toMap()).toList(),
    };
  }
}
