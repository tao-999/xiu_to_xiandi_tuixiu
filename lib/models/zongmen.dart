// lib/models/zongmen.dart

import 'dart:convert';
import 'package:meta/meta.dart';
import 'pill.dart';
import 'technique.dart';
import 'disciple.dart';

@immutable
class Zongmen {
  final String id;             // 唯一 ID
  final String name;           // 宗门名称
  final String founderName;    // 宗主（创建者）
  final String description;    // 宗门说明
  final String emblemPath;     // 徽章贴图路径
  final String specialization; // 修炼方向
  final DateTime createdAt;    // 创建时间

  /// —— 宗门经验系统 —— ///
  final int sectExp;           // 当前累计的宗门经验

  /// —— 宗门资源 —— ///
  final int spiritStoneLow;
  final int spiritStoneMid;
  final int spiritStoneHigh;
  final int spiritStoneSupreme;

  /// —— 子模块 —— ///
  final List<Pill> pills;
  final List<Technique> techniques;
  final List<Disciple> disciples;

  Zongmen({
    required this.id,
    required this.name,
    required this.founderName,
    this.description = '',
    required this.emblemPath,
    this.specialization = '',
    DateTime? createdAt,
    this.sectExp = 0,
    this.spiritStoneLow = 0,
    this.spiritStoneMid = 0,
    this.spiritStoneHigh = 0,
    this.spiritStoneSupreme = 0,
    this.pills = const [],
    this.techniques = const [],
    this.disciples = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Zongmen copyWith({
    String? id,
    String? name,
    String? founderName,
    String? description,
    String? emblemPath,
    String? specialization,
    DateTime? createdAt,
    int? sectExp,
    int? level,
    int? spiritStoneLow,
    int? spiritStoneMid,
    int? spiritStoneHigh,
    int? spiritStoneSupreme,
    List<Pill>? pills,
    List<Technique>? techniques,
    List<Disciple>? disciples,
  }) {
    return Zongmen(
      id: id ?? this.id,
      name: name ?? this.name,
      founderName: founderName ?? this.founderName,
      description: description ?? this.description,
      emblemPath: emblemPath ?? this.emblemPath,
      specialization: specialization ?? this.specialization,
      createdAt: createdAt ?? this.createdAt,
      sectExp: sectExp ?? this.sectExp,
      spiritStoneLow: spiritStoneLow ?? this.spiritStoneLow,
      spiritStoneMid: spiritStoneMid ?? this.spiritStoneMid,
      spiritStoneHigh: spiritStoneHigh ?? this.spiritStoneHigh,
      spiritStoneSupreme: spiritStoneSupreme ?? this.spiritStoneSupreme,
      pills: pills ?? this.pills,
      techniques: techniques ?? this.techniques,
      disciples: disciples ?? this.disciples,
    );
  }

  factory Zongmen.fromMap(Map<String, dynamic> map) {
    return Zongmen(
      id: map['id'] as String,
      name: map['name'] as String,
      founderName: map['founderName'] as String,
      description: map['description'] as String? ?? '',
      emblemPath: map['emblemPath'] as String,
      specialization: map['specialization'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      sectExp: map['sectExp'] as int? ?? 0,
      spiritStoneLow: map['spiritStoneLow'] as int? ?? 0,
      spiritStoneMid: map['spiritStoneMid'] as int? ?? 0,
      spiritStoneHigh: map['spiritStoneHigh'] as int? ?? 0,
      spiritStoneSupreme: map['spiritStoneSupreme'] as int? ?? 0,
      pills: (map['pills'] as List? ?? []).map((e) => Pill.fromMap(e)).toList(),
      techniques: (map['techniques'] as List? ?? [])
          .map((e) => Technique.fromMap(e))
          .toList(),
      disciples: (map['disciples'] as List? ?? [])
          .map((e) => Disciple.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'founderName': founderName,
    'description': description,
    'emblemPath': emblemPath,
    'specialization': specialization,
    'createdAt': createdAt.toIso8601String(),
    'sectExp': sectExp,
    'spiritStoneLow': spiritStoneLow,
    'spiritStoneMid': spiritStoneMid,
    'spiritStoneHigh': spiritStoneHigh,
    'spiritStoneSupreme': spiritStoneSupreme,
    'pills': pills.map((e) => e.toMap()).toList(),
    'techniques': techniques.map((e) => e.toMap()).toList(),
    'disciples': disciples.map((e) => e.toMap()).toList(),
  };
}
