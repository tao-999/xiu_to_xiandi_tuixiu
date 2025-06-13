import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/herb_material.dart';

class DanfangService {
  static const String _key = 'danfang_status';
  static const String _herbKey = 'herb_materials';

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

  // 🌿 草药背包持久化 =====================

  static Future<List<HerbMaterial>> loadHerbs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_herbKey);
    if (jsonStr == null) return [];

    final List decoded = json.decode(jsonStr);
    return decoded.map((e) => HerbMaterial.fromMap(e)).toList();
  }

  static Future<void> saveHerbs(List<HerbMaterial> herbs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(herbs.map((e) => e.toMap()).toList());
    await prefs.setString(_herbKey, encoded);
  }

  static Future<void> addHerb(String id, int count) async {
    final herbs = await loadHerbs();
    final index = herbs.indexWhere((e) => e.id == id);

    if (index >= 0) {
      herbs[index] = herbs[index].copyWith(quantity: herbs[index].quantity + count);
    } else {
      herbs.add(HerbMaterial(
        id: id,
        name: '未知草药',
        imagePath: '',
        description: '',
        quantity: count,
      ));
    }

    await saveHerbs(herbs);
  }

  static Future<bool> consumeHerb(String id, int count) async {
    final herbs = await loadHerbs();
    final index = herbs.indexWhere((e) => e.id == id);

    if (index >= 0 && herbs[index].quantity >= count) {
      herbs[index] = herbs[index].copyWith(quantity: herbs[index].quantity - count);
      await saveHerbs(herbs);
      return true;
    }

    return false;
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
