import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

/// 🌿 地形工具方法
class TerrainUtils {
  /// 🚀 Flood Fill: 从起点扩展，找同类地形组成的最小BoundingBox
  static Rect floodFillBoundingBox({
    required Vector2 start,
    required String terrainType,
    required String Function(Vector2) getTerrainType,
    double sampleStep = 32.0,
    int maxSteps = 2000,
  }) {
    final visited = <String>{};
    final queue = <Vector2>[];
    queue.add(start);

    double minX = start.x;
    double minY = start.y;
    double maxX = start.x;
    double maxY = start.y;

    int steps = 0;

    while (queue.isNotEmpty && steps < maxSteps) {
      final current = queue.removeLast();
      final key = '${current.x.toStringAsFixed(1)}_${current.y.toStringAsFixed(1)}';
      if (visited.contains(key)) continue;
      visited.add(key);

      final terrain = getTerrainType(current);

      if (terrain != terrainType) continue;

      minX = min(minX, current.x);
      minY = min(minY, current.y);
      maxX = max(maxX, current.x);
      maxY = max(maxY, current.y);

      // 四方向扩展
      queue.add(current + Vector2(sampleStep, 0));
      queue.add(current + Vector2(-sampleStep, 0));
      queue.add(current + Vector2(0, sampleStep));
      queue.add(current + Vector2(0, -sampleStep));

      steps++;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
