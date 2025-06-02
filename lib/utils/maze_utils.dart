import 'package:flame/components.dart';

Set<Vector2> getReachableTiles({
  required List<List<int>> grid,
  required Vector2 start,
}) {
  final visited = <Vector2>{};
  final queue = <Vector2>[start];
  visited.add(start);

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);

    for (final dir in [
      Vector2(1, 0),
      Vector2(-1, 0),
      Vector2(0, 1),
      Vector2(0, -1),
    ]) {
      final next = current + dir;
      final x = next.x.toInt();
      final y = next.y.toInt();

      if (x >= 0 &&
          y >= 0 &&
          y < grid.length &&
          x < grid[0].length &&
          grid[y][x] == 1 &&
          !visited.contains(next)) {
        visited.add(next);
        queue.add(next);
      }
    }
  }

  return visited;
}
