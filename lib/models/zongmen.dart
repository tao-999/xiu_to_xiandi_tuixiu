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

  final int sectLevel; // 🌟 新增宗门等级

  final List<Technique> techniques;

  Zongmen({
    required this.id,
    required this.name,
    required this.founderName,
    this.description = '',
    required this.emblemPath,
    this.specialization = '',
    DateTime? createdAt,
    this.sectLevel = 1, // 🌟 默认1级
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
    int? sectLevel,
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
      sectLevel: sectLevel ?? this.sectLevel,
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
      sectLevel: map['sectLevel'] ?? 1, // 🌟 新增
      techniques: (map['techniques'] as List? ?? [])
          .map((e) => Technique.fromMap(e))
          .toList(),
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
      'sectLevel': sectLevel, // 🌟 新增
      'techniques': techniques.map((e) => e.toMap()).toList(),
    };
  }
}
