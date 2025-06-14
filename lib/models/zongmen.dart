import 'dart:convert';
import 'package:meta/meta.dart';
import 'pill.dart';
import 'technique.dart';

@immutable
class Zongmen {
  final String id;
  final String name;
  final String founderName;
  final String description;
  final String emblemPath;
  final String specialization;
  final DateTime createdAt;

  final int sectExp;
  final int spiritStoneLow;
  final int spiritStoneMid;
  final int spiritStoneHigh;
  final int spiritStoneSupreme;

  final List<Pill> pills;
  final List<Technique> techniques;

  // ❗改动：不再包含 disciples，而是通过 Hive 独立持久化
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
    int? spiritStoneLow,
    int? spiritStoneMid,
    int? spiritStoneHigh,
    int? spiritStoneSupreme,
    List<Pill>? pills,
    List<Technique>? techniques,
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
    );
  }

  factory Zongmen.fromMap(Map<String, dynamic> map) {
    return Zongmen(
      id: map['id'],
      name: map['name'],
      founderName: map['founderName'],
      description: map['description'] ?? '',
      emblemPath: map['emblemPath'],
      specialization: map['specialization'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      sectExp: map['sectExp'] ?? 0,
      spiritStoneLow: map['spiritStoneLow'] ?? 0,
      spiritStoneMid: map['spiritStoneMid'] ?? 0,
      spiritStoneHigh: map['spiritStoneHigh'] ?? 0,
      spiritStoneSupreme: map['spiritStoneSupreme'] ?? 0,
      pills: (map['pills'] as List? ?? []).map((e) => Pill.fromMap(e)).toList(),
      techniques: (map['techniques'] as List? ?? [])
          .map((e) => Technique.fromMap(e))
          .toList(),
      // ❌ 不再从 JSON 加载 disciples
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      // ❌ 不再保存 disciples
    };
  }
}
