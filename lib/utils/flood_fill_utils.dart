import 'dart:collection';
import 'dart:math';

class FloodFillUtils {
  static void floodFillLandWithMerge({
    required Map<Point<int>, bool> landMap,
    required Map<Point<int>, int> regionMap,
    required Point<int> start,
    required int Function() nextRegionId,
  }) {
    if (!landMap.containsKey(start)) return;
    if (!landMap[start]!) return;
    if (regionMap.containsKey(start)) return;

    final queue = Queue<Point<int>>();
    final visited = <Point<int>>{};
    final mergeIds = <int>{};

    // 查看邻居
    for (final n in _neighbors(start)) {
      if (regionMap.containsKey(n) && landMap[n] == true) {
        mergeIds.add(regionMap[n]!);
      }
    }

    final regionId = mergeIds.isNotEmpty ? mergeIds.first : nextRegionId();

    queue.add(start);
    visited.add(start);
    regionMap[start] = regionId;

    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      for (final n in _neighbors(p)) {
        if (visited.contains(n)) continue;
        if (!landMap.containsKey(n)) continue;
        if (!landMap[n]!) continue;

        if (regionMap.containsKey(n)) {
          mergeIds.add(regionMap[n]!);
          continue;
        }

        visited.add(n);
        regionMap[n] = regionId;
        queue.add(n);
      }
    }

    if (mergeIds.length > 1) {
      for (final entry in regionMap.entries.toList()) {
        if (mergeIds.contains(entry.value)) {
          regionMap[entry.key] = regionId;
        }
      }
    }
  }

  static Iterable<Point<int>> _neighbors(Point<int> p) {
    return [
      Point(p.x + 1, p.y),
      Point(p.x - 1, p.y),
      Point(p.x, p.y + 1),
      Point(p.x, p.y - 1),
    ];
  }
}
