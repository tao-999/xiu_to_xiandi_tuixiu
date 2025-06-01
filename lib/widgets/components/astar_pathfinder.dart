// lib/widgets/components/astar_pathfinder.dart
import 'package:collection/collection.dart';
import 'package:flame/components.dart';

class AStarPathfinder {
  static List<Vector2> findPath(
      List<List<int>> grid,
      Vector2 start,
      Vector2 end,
      ) {
    final rows = grid.length;
    final cols = grid[0].length;

    bool isWalkable(int x, int y) =>
        x >= 0 && y >= 0 && x < cols && y < rows && grid[y][x] == 1;

    final startNode = _Node(start.x.toInt(), start.y.toInt());
    final endNode = _Node(end.x.toInt(), end.y.toInt());

    final openSet = PriorityQueue<_Node>((a, b) => a.f.compareTo(b.f));
    final closedSet = <String>{};

    startNode.g = 0;
    startNode.h = startNode.distanceTo(endNode);
    openSet.add(startNode);

    final cameFrom = <String, _Node>{};

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();

      if (current == endNode) {
        return _reconstructPath(cameFrom, current)
            .map((n) => Vector2(n.x.toDouble(), n.y.toDouble()))
            .toList();
      }

      closedSet.add(current.key);

      for (final dir in _Node.directions) {
        final nx = current.x + dir[0];
        final ny = current.y + dir[1];
        if (!isWalkable(nx, ny)) continue;

        final neighbor = _Node(nx, ny);
        if (closedSet.contains(neighbor.key)) continue;

        final tentativeG = current.g + 1;
        if (!openSet.contains(neighbor) || tentativeG < neighbor.g) {
          cameFrom[neighbor.key] = current;
          neighbor.g = tentativeG;
          neighbor.h = neighbor.distanceTo(endNode);
          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return []; // 无路可走
  }

  static List<_Node> _reconstructPath(
      Map<String, _Node> cameFrom, _Node current) {
    final totalPath = [current];
    while (cameFrom.containsKey(current.key)) {
      current = cameFrom[current.key]!;
      totalPath.insert(0, current);
    }
    return totalPath;
  }
}

class _Node {
  final int x, y;
  double g = double.infinity;
  double h = 0;

  static const directions = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1]
  ];

  _Node(this.x, this.y);

  double get f => g + h;
  String get key => '$x,$y';

  double distanceTo(_Node other) =>
      ((x - other.x).abs() + (y - other.y).abs()).toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _Node && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
