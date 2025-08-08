import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../services/terrain_event_storage_service.dart';
import '../widgets/components/shallow_ocean_terrain_event.dart';

class TerrainEventUtil {
  /// game参数必须传
  static Future<bool> checkAndTrigger(
      String terrain,
      Vector2 pos,
      FlameGame game,
      ) async {
    // 🌟先统一检查
    final triggered = await TerrainEventStorageService.getTriggeredEvents(terrain, pos);
    if (triggered.isNotEmpty) {
      return false;
    }

    bool hasEvent = false;

    switch (terrain) {
      case 'shallow_ocean':
        hasEvent = await ShallowOceanTerrainEvent.trigger(pos, game);
        break;
    }

    // 🌟如果没事件，也要写NONE
    if (!hasEvent) {
      await TerrainEventStorageService.markTriggered(
        terrain,
        pos,
        'NONE',
        data: {},
        status: 'completed',
      );
    }

    return hasEvent;
  }
}
