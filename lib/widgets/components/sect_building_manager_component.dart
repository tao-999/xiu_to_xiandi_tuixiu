import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'sect_building_component.dart';

class SectBuildingManagerComponent extends Component {
  final Component grid;
  final double mapWidth;
  final double mapHeight;
  final double buildingRadius = 150;
  final double imageSize = 100;
  final Vector2 Function() getLogicalOffset;

  final List<_MovingBuilding> _buildings = [];

  SectBuildingManagerComponent({
    required this.grid,
    required this.mapWidth,
    required this.mapHeight,
    required this.getLogicalOffset,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _spawnBuilding('炼器房', 'zongmen/lianqi.png');
    await _spawnBuilding('弟子闺房', 'zongmen/dizi.png');
  }

  Future<void> _spawnBuilding(String name, String imagePath) async {
    final image = await Flame.images.load(imagePath);
    final random = Random();

    final double minX = buildingRadius;
    final double maxX = mapWidth - buildingRadius;
    final double minY = buildingRadius;
    final double maxY = mapHeight - buildingRadius;

    final worldPosition = Vector2(
      random.nextDouble() * (maxX - minX) + minX,
      random.nextDouble() * (maxY - minY) + minY,
    );

    final angle = random.nextDouble() * pi * 2;
    final speed = 35.0 + random.nextDouble() * 10;
    final velocity = Vector2(cos(angle), sin(angle)) * speed;

    final building = SectBuildingComponent(
      buildingName: name,
      image: image,
      imageSize: imageSize,
      worldPosition: worldPosition.clone(),
      circleRadius: buildingRadius,
      onTap: null,
      priority: 2,
    );

    _buildings.add(_MovingBuilding(building, velocity));
    await grid.add(building);

    debugPrint('🏠 初次生成建筑: $name → 位置: $worldPosition');
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offset = getLogicalOffset();

    for (final moving in _buildings) {
      moving.building.worldPosition += moving.velocity * dt;

      final pos = moving.building.worldPosition;
      final minX = buildingRadius;
      final maxX = mapWidth - buildingRadius;
      final minY = buildingRadius;
      final maxY = mapHeight - buildingRadius;

      if (pos.x < minX) {
        moving.building.worldPosition.x = minX;
        moving.velocity.x *= -1;
      } else if (pos.x > maxX) {
        moving.building.worldPosition.x = maxX;
        moving.velocity.x *= -1;
      }

      if (pos.y < minY) {
        moving.building.worldPosition.y = minY;
        moving.velocity.y *= -1;
      } else if (pos.y > maxY) {
        moving.building.worldPosition.y = maxY;
        moving.velocity.y *= -1;
      }

      moving.building.updateVisualPosition(offset);
    }

    // 💥 建筑之间互相弹开
    for (int i = 0; i < _buildings.length; i++) {
      for (int j = i + 1; j < _buildings.length; j++) {
        final a = _buildings[i];
        final b = _buildings[j];

        final delta = b.building.worldPosition - a.building.worldPosition;
        final distance = delta.length;
        final minDist = buildingRadius * 2;

        if (distance < minDist && distance > 0.01) {
          final overlap = minDist - distance;
          final pushDir = delta.normalized();

          a.building.worldPosition -= pushDir * (overlap / 2);
          b.building.worldPosition += pushDir * (overlap / 2);

          a.velocity = -a.velocity;
          b.velocity = -b.velocity;
        }
      }
    }
  }
}

class _MovingBuilding {
  final SectBuildingComponent building;
  Vector2 velocity;

  _MovingBuilding(this.building, this.velocity);
}
