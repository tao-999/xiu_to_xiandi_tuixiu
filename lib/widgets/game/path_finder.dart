import 'package:flame/components.dart';
import 'dart:math';

class PathFinder {
  final List<List<bool>> grid; // 地图网格，每个格子是否被障碍物占用
  final int rows, cols;
  final double tileSize;

  PathFinder({required this.grid, required this.tileSize})
      : rows = grid.length,
        cols = grid[0].length;

  // A* 寻路算法
  List<Vector2> findPath(Vector2 start, Vector2 end) {
    // Convert start/end positions to grid coordinates
    final startNode = _toGridCoordinates(start);
    final endNode = _toGridCoordinates(end);

    final openSet = <Node>{};
    final closedSet = <Node>{};
    final cameFrom = <Node, Node>{};
    final gScore = <Node, double>{};
    final fScore = <Node, double>{};

    // Initialize nodes
    Node startNodeObj = Node(startNode.x, startNode.y);
    Node endNodeObj = Node(endNode.x, endNode.y);

    openSet.add(startNodeObj);
    gScore[startNodeObj] = 0;
    fScore[startNodeObj] = _heuristic(startNodeObj, endNodeObj);

    while (openSet.isNotEmpty) {
      // Get the node with the lowest fScore
      Node current = _getLowestFScoreNode(openSet, fScore);

      if (current == endNodeObj) {
        return _reconstructPath(cameFrom, current);
      }

      openSet.remove(current);
      closedSet.add(current);

      // Explore neighbors
      for (final neighbor in _getNeighbors(current)) {
        if (closedSet.contains(neighbor)) continue;

        double tentativeGScore = gScore[current]! + _distance(current, neighbor);

        if (!openSet.contains(neighbor) || tentativeGScore < gScore[neighbor]!) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = gScore[neighbor]! + _heuristic(neighbor, endNodeObj);

          if (!openSet.contains(neighbor)) openSet.add(neighbor);
        }
      }
    }

    // No path found
    return [];
  }

  // Convert world coordinates to grid coordinates
  Node _toGridCoordinates(Vector2 position) {
    int col = (position.x / tileSize).floor();
    int row = (position.y / tileSize).floor();
    return Node(col, row);
  }

  // Reconstruct the path from the cameFrom map
  List<Vector2> _reconstructPath(Map<Node, Node> cameFrom, Node current) {
    List<Vector2> path = [];
    while (cameFrom.containsKey(current)) {
      path.add(Vector2(current.x * tileSize + tileSize / 2, current.y * tileSize + tileSize / 2));
      current = cameFrom[current]!;
    }
    return path.reversed.toList();
  }

  // Get neighboring nodes (4 directions)
  List<Node> _getNeighbors(Node node) {
    List<Node> neighbors = [];
    List<List<int>> directions = [
      [-1, 0], // up
      [1, 0],  // down
      [0, -1], // left
      [0, 1],  // right
    ];

    for (var direction in directions) {
      int newRow = node.y + direction[0];
      int newCol = node.x + direction[1];

      if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols && !grid[newRow][newCol]) {
        neighbors.add(Node(newCol, newRow));
      }
    }

    return neighbors;
  }

  // Calculate heuristic (Manhattan distance)
  double _heuristic(Node a, Node b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }

  // Calculate distance between two nodes
  double _distance(Node a, Node b) {
    return _heuristic(a, b);
  }

  // Get the node with the lowest fScore
  Node _getLowestFScoreNode(Set<Node> openSet, Map<Node, double> fScore) {
    return openSet.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);
  }
}

class Node {
  final int x, y;
  Node(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return other is Node && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
