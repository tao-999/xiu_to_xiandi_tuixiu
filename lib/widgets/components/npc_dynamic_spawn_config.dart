import 'dart:ui';

import 'package:flame/components.dart';

class NpcDynamicSpawnConfig {
  final String terrain;
  final Vector2 position;
  final double triggerRadius;
  final String spritePath;
  final Vector2 size;
  final double speed;
  final Rect movementBounds;
  final bool defaultFacingRight;
  bool spawned = false;

  NpcDynamicSpawnConfig({
    required this.terrain,
    required this.position,
    required this.triggerRadius,
    required this.spritePath,
    required this.size,
    required this.speed,
    required this.movementBounds,
    this.defaultFacingRight = true,
  });
}
