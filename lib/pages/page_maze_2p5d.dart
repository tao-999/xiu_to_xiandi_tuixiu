import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/maze_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/back_button_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/maze_renderer.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/maze_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/astar_pathfinder.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/enemy_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/maze_chest_spawner.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/exit_detector_component.dart';

class Maze2p5DPage extends StatefulWidget {
  const Maze2p5DPage({super.key});

  @override
  State<Maze2p5DPage> createState() => _Maze2p5DPageState();
}

class _Maze2p5DPageState extends State<Maze2p5DPage> {
  int currentFloor = 1;

  @override
  void initState() {
    super.initState();
    _loadFloor();
  }

  Future<void> _loadFloor() async {
    final floor = await MazeStorage.loadCurrentFloor();
    setState(() => currentFloor = floor);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: Maze2p5DGame(onNextFloor: _goToNextFloor)),
        const BackButtonOverlay(),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '第 $currentFloor 层',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToNextFloor() async {
    await MazeStorage.clearAllMazeData();
    await MazeStorage.saveCurrentFloor(currentFloor + 1);
    setState(() => currentFloor++);
  }
}

class Maze2p5DGame extends FlameGame with HasCollisionDetection {
  static const int rows = 27;
  static const int cols = 27;
  static const double tileSize = 48;
  static const double wallHeight = 8;

  final VoidCallback onNextFloor;
  Maze2p5DGame({required this.onNextFloor});

  late List<List<int>> grid;
  late final PositionComponent mapLayer;
  late Vector2 entry;
  late Vector2 exit;
  late MazePlayerComponent player;

  TextComponent? marker;

  @override
  Future<void> onLoad() async {
    final gender = await PlayerStorage.getField<String>('gender') ?? 'male';
    final savedGrid = await MazeStorage.loadMazeGrid();
    final savedEntry = await MazeStorage.loadEntry();
    final savedExit = await MazeStorage.loadExit();
    final savedPlayerPos = await MazeStorage.getPlayerPosition();

    if (savedGrid != null && savedEntry != null && savedExit != null) {
      grid = savedGrid;
      entry = savedEntry;
      exit = savedExit;
    } else {
      grid = List.generate(rows, (y) => List.generate(cols, (x) => 0));
      _generateEntryAndExit();
      _digMaze(entry.x.toInt(), entry.y.toInt());
      grid[entry.y.toInt()][entry.x.toInt()] = 1;
      grid[exit.y.toInt()][exit.x.toInt()] = 1;
      await MazeStorage.saveMaze(grid, entry, exit);
    }

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

    final currentFloor = await MazeStorage.loadCurrentFloor();

    mapLayer.add(MazeChestSpawner(
      grid: grid,
      tileSize: tileSize,
      excluded: {entry, exit},
      currentFloor: currentFloor,
    ));

    final playerSprite = await loadSprite(
      gender == 'female' ? 'icon_youli_female.png' : 'icon_youli_male.png',
    );

    final startPos = savedPlayerPos ?? entry * tileSize + Vector2.all(tileSize / 2);
    player = MazePlayerComponent(
      sprite: playerSprite,
      grid: grid,
      tileSize: tileSize,
      position: startPos,
      onCollideWithChest: () async {
        // ✅ 可保留也可删
        final chestOpened = await MazeStorage.getChestOpened();
        final enemies = await MazeStorage.loadEnemyStates();
        final killed = await MazeStorage.getKilledEnemies();
        final remaining = enemies?.where((e) => !killed.any((k) => k.x == e.x && k.y == e.y)).toList() ?? [];
        final playerTile = player.gridPosition;
        if (chestOpened && remaining.isEmpty) {
          if ((playerTile.x - exit.x).abs() < 0.1 && (playerTile.y - exit.y).abs() < 0.1) {
            onNextFloor();
          }
        }
      },
    );
    mapLayer.add(player);

    mapLayer.add(EnemySpawner(
      grid: grid,
      tileSize: tileSize,
      excluded: {entry, exit},
      currentFloor: currentFloor,
    ));

    // ✅ 新增：出口检测器组件
    mapLayer.add(ExitDetectorComponent(
      exitTile: exit,
      tileSize: tileSize,
      currentFloor: currentFloor,
      onNextFloor: onNextFloor,
    ));

    add(DragMap(
      onDragged: _onDragged,
      onTap: _handleTap,
    ));

    camera.viewfinder.zoom = 1.0;
    await Future.delayed(Duration.zero);
    _centerMapOn(player.position / tileSize);
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

    final safeRows = rows - 2;
    final safeCols = cols - 2;

    for (int i = 1; i < safeCols; i += 2) {
      edgePoints.add(Vector2(i.toDouble(), 1));
      edgePoints.add(Vector2(i.toDouble(), (rows - 2).toDouble()));
    }
    for (int j = 1; j < safeRows; j += 2) {
      edgePoints.add(Vector2(1, j.toDouble()));
      edgePoints.add(Vector2((cols - 2).toDouble(), j.toDouble()));
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
