import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/maze_renderer.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/maze_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/chest_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/astar_pathfinder.dart';

class Maze2p5DPage extends StatelessWidget {
  const Maze2p5DPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: Maze2p5DGame()),
        const BackButtonOverlay(),
      ],
    );
  }
}

class Maze2p5DGame extends FlameGame with HasCollisionDetection {
  static const int rows = 41;
  static const int cols = 41;
  static const double tileSize = 48;
  static const double wallHeight = 8;

  late final List<List<int>> grid;
  late final PositionComponent mapLayer;
  late Vector2 entry;
  late Vector2 exit;
  late ChestComponent chest;
  late MazePlayerComponent player;

  TextComponent? marker;

  @override
  Future<void> onLoad() async {
    final gender = await PlayerStorage.getField<String>('gender') ?? 'male';

    grid = List.generate(rows, (y) => List.generate(cols, (x) => 0));
    _generateEntryAndExit();
    _digMaze(entry.x.toInt(), entry.y.toInt());

    grid[entry.y.toInt()][entry.x.toInt()] = 1;
    grid[exit.y.toInt()][exit.x.toInt()] = 1;

    mapLayer = PositionComponent()
      ..anchor = Anchor.topLeft
      ..size = Vector2(cols * tileSize, rows * tileSize);
    add(mapLayer);

    mapLayer.add(FloorComponent(rows: rows, cols: cols, tileSize: tileSize));
    mapLayer.add(MazeRenderer(
      grid: grid,
      entry: entry,
      exit: exit,
      tileSize: tileSize,
      wallHeight: wallHeight,
    ));

    final validTiles = <Vector2>[];
    for (int y = 1; y < rows - 1; y++) {
      for (int x = 1; x < cols - 1; x++) {
        if (grid[y][x] == 1 && !(entry.x == x && entry.y == y)) {
          validTiles.add(Vector2(x.toDouble(), y.toDouble()));
        }
      }
    }
    validTiles.shuffle();
    final chestGrid = validTiles.first;

    final chestSprite = await loadSprite('migong_baoxiang.png');
    final chestOpenSprite = await loadSprite('migong_baoxiang_open.png');
    chest = ChestComponent(
      closedSprite: chestSprite,
      openSprite: chestOpenSprite,
      position: chestGrid * tileSize + Vector2.all(tileSize / 2),
    );
    mapLayer.add(chest);

    final playerSprite = await loadSprite(
      gender == 'female' ? 'icon_youli_female.png' : 'icon_youli_male.png',
    );
    player = MazePlayerComponent(
      sprite: playerSprite,
      grid: grid,
      tileSize: tileSize,
      position: Vector2(
        entry.x * tileSize + tileSize / 2,
        entry.y * tileSize + tileSize / 2,
      ),
      onCollideWithChest: () => chest.open(),
    );
    mapLayer.add(player);

    add(DragMap(
      onDragged: _onDragged,
      onTap: _handleTap,
    ));

    camera.viewfinder.zoom = 1.0;

    await Future.delayed(Duration.zero);
    _centerMapOn(entry);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (marker != null && player.position.distanceTo(marker!.position) < 5.0) {
      marker!.removeFromParent();
      marker = null;
    }
  }

  void _handleTap(Vector2 tapInScreen) {
    print("🤣🤣🤣🤣🤣🤣");
    final tapInWorld = tapInScreen - mapLayer.position;

    final gx = (tapInWorld.x / tileSize).floor();
    final gy = (tapInWorld.y / tileSize).floor();

    if (gx >= 0 && gx < cols && gy >= 0 && gy < rows && grid[gy][gx] == 1) {
      final target = Vector2(gx.toDouble(), gy.toDouble());
      final path = AStarPathfinder.findPath(grid, player.gridPosition, target);
      player.followPath(path);

      marker?.removeFromParent();
      marker = TextComponent(
        text: '📍',
        anchor: Anchor.center,
        position: target * tileSize + Vector2.all(tileSize / 2),
        priority: 998,
      );
      mapLayer.add(marker!);
    }
  }

  void _centerMapOn(Vector2 target) {
    final screenCenter = size / 2;
    final targetInWorld = target * tileSize;
    mapLayer.position = screenCenter - targetInWorld;
    _clampPosition();
  }

  void _onDragged(Vector2 delta) {
    if (!player.isMoving) {
      mapLayer.position += delta;
      _clampPosition();
    }
  }

  void _clampPosition() {
    final screen = size;
    final scaledSize = mapLayer.size.clone()..multiply(mapLayer.scale);

    final minX = screen.x - scaledSize.x;
    final minY = screen.y - scaledSize.y;

    mapLayer.position.x = mapLayer.position.x.clamp(minX, 0.0);
    mapLayer.position.y = mapLayer.position.y.clamp(minY, 0.0);
  }

  void _generateEntryAndExit() {
    final rand = Random();
    final edgePoints = <Vector2>[];

    // ⚠️ 改成倒数第二层而不是边缘
    for (int i = 2; i < cols - 2; i += 2) {
      edgePoints.add(Vector2(i.toDouble(), 1)); // 上边偏内
      edgePoints.add(Vector2(i.toDouble(), (rows - 2).toDouble())); // 下边偏内
    }
    for (int j = 2; j < rows - 2; j += 2) {
      edgePoints.add(Vector2(1, j.toDouble())); // 左边偏内
      edgePoints.add(Vector2((cols - 2).toDouble(), j.toDouble())); // 右边偏内
    }

    edgePoints.shuffle();
    entry = edgePoints.removeLast();
    exit = edgePoints.firstWhere((p) => p != entry);
  }

  void _digMaze(int x, int y) {
    final dirs = [Offset(2, 0), Offset(-2, 0), Offset(0, 2), Offset(0, -2)]..shuffle();
    grid[y][x] = 1;
    for (final d in dirs) {
      final nx = x + d.dx.toInt();
      final ny = y + d.dy.toInt();
      if (nx > 0 && ny > 0 && nx < cols - 1 && ny < rows - 1 && grid[ny][nx] == 0) {
        grid[y + d.dy ~/ 2][x + d.dx ~/ 2] = 1;
        _digMaze(nx, ny);
      }
    }
  }
}

class FloorComponent extends PositionComponent {
  final int rows, cols;
  final double tileSize;

  FloorComponent({required this.rows, required this.cols, required this.tileSize});

  @override
  Future<void> onLoad() async {
    size = Vector2(cols * tileSize, rows * tileSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFDDDDDD));
  }
}
