import 'package:hive/hive.dart';
import 'package:flame/components.dart';

class TerrainEventStorageService {
  static Box? _box;

  static Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox('terrain_events');
    }
    return _box!;
  }

  static Future<bool> hasTriggered(
      String terrain, Vector2 pos, String eventType) async {
    final box = await _getBox();
    final key = _getKey(terrain, pos);

    final recordsRaw = box.get(key);
    if (recordsRaw == null) return false;

    final records = (recordsRaw as List).cast<Map>();
    return records.any((e) => e['eventType'] == eventType);
  }

  static Future<void> markTriggered(
      String terrain,
      Vector2 pos,
      String eventType, {
        Map<String, dynamic>? data,
        String status = 'completed', // 🌟默认“已完成”
      }) async {
    final box = await _getBox();
    final key = _getKey(terrain, pos);

    final List<dynamic> records = box.get(key)?.cast<Map>() ?? [];

    if (records.any((e) => e['eventType'] == eventType)) {
      return;
    }

    final record = {
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      'status': status,
      'data': data ?? {},
    };

    records.add(record);
    await box.put(key, records);
  }

  static Future<List<Map>> getTriggeredEvents(
      String terrain, Vector2 pos) async {
    final box = await _getBox();
    final key = _getKey(terrain, pos);

    final recordsRaw = box.get(key);
    if (recordsRaw == null) return [];
    return (recordsRaw as List).cast<Map>();
  }

  /// 🌟这里加tileSize
  static String _getKey(String terrain, Vector2 pos, {int tileSize = 64}) {
    final tx = (pos.x / tileSize).floor();
    final ty = (pos.y / tileSize).floor();
    return '$terrain:$tx:$ty';
  }
}
