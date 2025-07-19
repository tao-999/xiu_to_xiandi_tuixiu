import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../services/terrain_event_storage_service.dart';
import '../widgets/components/beach_terrain_event.dart';
import '../widgets/components/flower_field_terrain_event.dart';
import '../widgets/components/forest_terrain_event.dart';
import '../widgets/components/grass_terrain_event.dart';
import '../widgets/components/rock_terrain_event.dart';
import '../widgets/components/volcanic_terrain_event.dart';
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
      case 'forest':
        hasEvent = await ForestTerrainEvent.trigger(pos, game);
        break;
      case 'rock':
        hasEvent = await RockTerrainEvent.trigger(pos, game);
        break;
      case 'volcanic':
        hasEvent = await VolcanicTerrainEvent.trigger(pos, game);
        break;
      case 'grass':
        hasEvent = await GrassTerrainEvent.trigger(pos, game);
        break;
      case 'flower_field':
        hasEvent = await FlowerFieldTerrainEvent.trigger(pos, game);
        break;
      case 'beach':
        hasEvent = await BeachTerrainEvent.trigger(pos, game);
        break;
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
