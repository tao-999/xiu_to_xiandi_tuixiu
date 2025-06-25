// lib/utils/sect_role_limits.dart

import 'package:flutter/material.dart';
import '../models/disciple.dart';

class SectRole {
  final String name;
  final bool isUnique;
  final int Function(int level) maxCount;
  final bool showOnMap;

  const SectRole({
    required this.name,
    required this.isUnique,
    required this.maxCount,
    this.showOnMap = true,
  });
}

class SectRoleLimits {
  static final Map<String, SectRole> roles = {
    '宗主': SectRole(
      name: '宗主',
      isUnique: true,
      maxCount: (_) => 1,
    ),
    '宗主夫人': SectRole(
      name: '宗主夫人',
      isUnique: true,
      maxCount: (_) => 1,
    ),
    '长老': SectRole(
      name: '长老',
      isUnique: false,
      maxCount: (level) => level >= 2 ? level - 1 : 0, // ✅ 2级起解锁
    ),
    '执事': SectRole(
      name: '执事',
      isUnique: false,
      maxCount: (level) => level >= 2 ? level - 1 : 0, // ✅ 同理
    ),
    '弟子': SectRole(
      name: '弟子',
      isUnique: false,
      maxCount: (_) => 99999,
      showOnMap: false,
    ),
  };

  static int getMax(String role, int sectLevel) {
    return roles[role]?.maxCount(sectLevel) ?? 99999;
  }

  static bool isRoleFull(String role, Map<String, List<Disciple>> groupedMap, int sectLevel) {
    final current = groupedMap[role]?.length ?? 0;
    return current >= getMax(role, sectLevel);
  }

  static List<SectRole> get visibleRoles =>
      roles.values.where((r) => r.showOnMap).toList();

  static Color getRoleColor(String role) {
    switch (role) {
      case '宗主':
        return Colors.amber;
      case '宗主夫人':
        return Colors.pinkAccent;
      case '长老':
        return Colors.redAccent;
      case '执事':
        return Colors.green;
      default:
        return Colors.black87;
    }
  }
}
