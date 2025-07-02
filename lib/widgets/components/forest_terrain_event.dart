import 'dart:math';
import 'package:flame/components.dart';
import '../../services/terrain_event_storage_service.dart';

class ForestTerrainEvent {
  static Future<bool> trigger(Vector2 pos) async {
    final distance = pos.length;

    if (_roll(0.3)) {
      final reward = (distance / 10).round();
      print('🌲 森林: 采集灵草，灵石+$reward');
      await TerrainEventStorageService.markTriggered(
        'forest',
        pos,
        'GATHER_FOREST_HERB',
        data: {'reward': reward},
      );
      return true; // 🌟表示有事件
    }

    return false; // 🌟表示没有事件
  }

  static bool _roll(double probability) {
    return Random().nextDouble() < probability;
  }
}
