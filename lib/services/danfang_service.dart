import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DanfangService {
  static const String _key = 'danfang_status';

  static Future<void> saveStatus({
    required DateTime lastCollectTime,
    required int outputLevel,
    required int outputPerHour,
    required int cooldownSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'lastCollectTime': lastCollectTime.toIso8601String(),
      'outputLevel': outputLevel,
      'outputPerHour': outputPerHour,
      'cooldownSeconds': cooldownSeconds,
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<DanfangStatus> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return DanfangStatus.initial();

    final map = jsonDecode(raw);
    return DanfangStatus(
      lastCollectTime: DateTime.parse(map['lastCollectTime']),
      outputLevel: map['outputLevel'],
      outputPerHour: map['outputPerHour'],
      cooldownSeconds: map['cooldownSeconds'],
    );
  }

  static Future<void> clearStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DanfangStatus {
  final DateTime lastCollectTime;
  final int outputLevel;
  final int outputPerHour;
  final int cooldownSeconds;

  DanfangStatus({
    required this.lastCollectTime,
    required this.outputLevel,
    required this.outputPerHour,
    required this.cooldownSeconds,
  });

  factory DanfangStatus.initial() {
    return DanfangStatus(
      lastCollectTime: DateTime.now().subtract(const Duration(hours: 1)),
      outputLevel: 1,
      outputPerHour: 5,
      cooldownSeconds: 3600,
    );
  }
}
