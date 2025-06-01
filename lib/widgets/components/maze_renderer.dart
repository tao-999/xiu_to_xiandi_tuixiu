import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MazeRenderer extends PositionComponent {
  final List<List<int>> grid;
  final Vector2 entry;
  final Vector2 exit;
  final double tileSize;
  final double wallHeight;

  MazeRenderer({
    required this.grid,
    required this.entry,
    required this.exit,
    required this.tileSize,
    required this.wallHeight,
  });

  @override
  Future<void> onLoad() async {
    final rows = grid.length;
    final cols = grid[0].length;

    _digExitTunnel(); // 🔧 确保出口不孤立

    for (int y = 1; y < rows - 1; y++) {
      for (int x = 1; x < cols - 1; x++) {
        if (grid[y][x] == 1) {
          add(_PathTile(gridX: x, gridY: y, tileSize: tileSize));
        } else if (_isAdjacentToPath(x, y) && !_shouldSkipWall(x, y)) {
          add(_WallTile(
            gridX: x,
            gridY: y,
            tileSize: tileSize,
            height: wallHeight,
          ));
        }
      }
    }

    add(_GlowMarker(
      gridX: entry.x.toInt(),
      gridY: entry.y.toInt(),
      tileSize: tileSize,
      color: Colors.blueAccent,
    ));
    add(_GlowMarker(
      gridX: exit.x.toInt(),
      gridY: exit.y.toInt(),
      tileSize: tileSize,
      color: Colors.orangeAccent,
    ));
  }

  void _digExitTunnel() {
    final x = exit.x.toInt();
    final y = exit.y.toInt();

    if (x == 0 && x + 1 < grid[0].length) grid[y][x + 1] = 1;
    if (x == grid[0].length - 1 && x - 1 >= 0) grid[y][x - 1] = 1;
    if (y == 0 && y + 1 < grid.length) grid[y + 1][x] = 1;
    if (y == grid.length - 1 && y - 1 >= 0) grid[y - 1][x] = 1;
  }

  bool _isAdjacentToPath(int x, int y) {
    const dx = [-1, 1, 0, 0];
    const dy = [0, 0, -1, 1];
    for (int i = 0; i < 4; i++) {
      final nx = x + dx[i], ny = y + dy[i];
      if (nx >= 0 && ny >= 0 && ny < grid.length && nx < grid[0].length && grid[ny][nx] == 1) {
        return true;
      }
    }
    return false;
  }

  bool _shouldSkipWall(int x, int y) {
    final entryX = entry.x.toInt();
    final entryY = entry.y.toInt();
    final exitX = exit.x.toInt();
    final exitY = exit.y.toInt();

    if ((x == entryX && y == entryY) || (x == exitX && y == exitY)) return true;

    if ((x - entryX).abs() <= 1 && (y - entryY).abs() <= 1) return true;
    if ((x - exitX).abs() <= 1 && (y - exitY).abs() <= 1) return true;

    return false;
  }
}

class _PathTile extends PositionComponent {
  final int gridX, gridY;
  final double tileSize;

  _PathTile({required this.gridX, required this.gridY, required this.tileSize}) {
    position = Vector2(gridX * tileSize, gridY * tileSize);
    size = Vector2.all(tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFEEEEEE));
  }
}

class _WallTile extends PositionComponent {
  final int gridX, gridY;
  final double tileSize, height;

  _WallTile({required this.gridX, required this.gridY, required this.tileSize, required this.height}) {
    position = Vector2(gridX * tileSize, gridY * tileSize - height);
    size = Vector2.all(tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    final w = tileSize, h = height;
    final bodyPaint = Paint()..color = const Color(0xFF888888);
    final topPaint = Paint()..color = const Color(0xFFAAAAAA);
    final sidePaint = Paint()..color = const Color(0xFF666666);

    final front = Path()
      ..moveTo(0, h + w)
      ..lineTo(w, h + w)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final top = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w - 6, 0)
      ..lineTo(6, 0)
      ..close();

    final side = Path()
      ..moveTo(w, h)
      ..lineTo(w, h + w)
      ..lineTo(w - 6, w)
      ..lineTo(w - 6, 0)
      ..close();

    canvas.drawPath(front, bodyPaint);
    canvas.drawPath(top, topPaint);
    canvas.drawPath(side, sidePaint);
  }
}

class _GlowMarker extends PositionComponent {
  final int gridX, gridY;
  final double tileSize;
  final Color color;

  _GlowMarker({
    required this.gridX,
    required this.gridY,
    required this.tileSize,
    required this.color,
  }) {
    position = Vector2(gridX * tileSize, gridY * tileSize);
    size = Vector2.all(tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2.2, glowPaint);
    canvas.drawCircle(center, size.x / 4, Paint()..color = color);
  }
}