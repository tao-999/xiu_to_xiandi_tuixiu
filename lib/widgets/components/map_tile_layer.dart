import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

enum MapStyle {
  grass,
  mud,
  stone,
  sand,
  snow,
  lava,
  water,
}

class MapTileLayer extends PositionComponent {
  final int rows;
  final int cols;
  final double tileSize;
  final int currentFloor;
  final TileManager tileManager;

  late final Vector2 mapSize;
  late final List<List<MapStyle>> tileStyles;
  late final Map<MapStyle, Sprite> styleSprites;

  final List<Point<int>> bossCandidateTiles = [];
  late List<List<int>> _grid;

  Size screenSize = const Size(640, 360);

  MapTileLayer({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.currentFloor,
    required this.tileManager,
  }) {
    mapSize = Vector2(cols * tileSize, rows * tileSize);
    size = mapSize;
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }

  void setSafeScreenSize(Size newSize) {
    if (!newSize.width.isNaN && !newSize.height.isNaN) {
      screenSize = newSize;
    }
  }

  @override
  Future<void> onLoad() async {
    await _loadSprites();
    await _buildWalls();
    tileStyles = _generateVoronoiTiles();
    await _buildTiles();
    await _spawnGroupedDecorObstacles();
    buildGrid();
  }

  Future<void> _loadSprites() async {
    styleSprites = {
      MapStyle.grass: await Sprite.load('tietu_caodi.webp'),
      MapStyle.mud: await Sprite.load('tietu_nidi.webp'),
      MapStyle.stone: await Sprite.load('tietu_shidi.webp'),
      MapStyle.sand: await Sprite.load('tietu_shadi.webp'),
      MapStyle.snow: await Sprite.load('tietu_xuedi.webp'),
      MapStyle.lava: await Sprite.load('tietu_rongyandi.webp'),
      MapStyle.water: await Sprite.load('tietu_shuiyu.webp'),
    };
  }

  Future<void> _buildWalls() async {
    for (int y = 0; y < rows - 1; y += 2) {
      for (int x = 0; x < cols - 1; x += 2) {
        final isOuter = x <= 1 || y <= 1 || x >= cols - 3 || y >= rows - 3;
        final isInner = x <= 3 || y <= 3 || x >= cols - 5 || y >= rows - 5;

        if (isOuter) {
          await _addBigWall(x, y, 'tietu_caodi.webp', 'tietu_dashu.png');
        } else if (isInner) {
          await _addBigWall(x, y, 'tietu_caodi.webp', 'tietu_caocong.png');
        }
      }
    }
  }

  Future<void> _addBigWall(int x, int y, String basePath, String decorPath) async {
    if (tileManager.isOccupied(x, y, 2, 2)) return;
    tileManager.occupy(x, y, 2, 2);

    final base = await Sprite.load(basePath);
    final decor = await Sprite.load(decorPath);

    for (int dx = 0; dx <= 1; dx++) {
      for (int dy = 0; dy <= 1; dy++) {
        final px = x + dx;
        final py = y + dy;
        add(SpriteComponent()
          ..sprite = base
          ..size = Vector2.all(tileSize)
          ..position = Vector2(px * tileSize, py * tileSize)
          ..priority = 0);
      }
    }

    add(SpriteComponent()
      ..sprite = decor
      ..size = Vector2(tileSize * 2, tileSize * 2)
      ..position = Vector2(x * tileSize, y * tileSize)
      ..priority = 5);
  }

  Future<void> _buildTiles() async {
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (tileManager.isTileOccupied(x, y)) continue;
        final style = tileStyles[y][x];
        final sprite = styleSprites[style]!;
        add(SpriteComponent()
          ..sprite = sprite
          ..size = Vector2.all(tileSize)
          ..position = Vector2(x * tileSize, y * tileSize)
          ..priority = 0);
      }
    }
  }

  Future<void> _spawnGroupedDecorObstacles() async {
    final rand = Random(currentFloor + 77);
    final decorGroups = [
      {'image': 'tietu_dashu.png', 'count': 5},
      {'image': 'tietu_caocong.png', 'count': 6},
      {'image': 'tietu_mogu.png', 'count': 6},
      {'image': 'tietue_gouhuo.png', 'count': 2},
    ];

    for (final group in decorGroups) {
      int placed = 0;
      final int groupCount = group['count'] as int;

      while (placed < groupCount) {
        final x = rand.nextInt(cols - 4);
        final y = rand.nextInt(rows - 4);

        bool canPlaceGroup = true;
        for (int dx = 0; dx < 2; dx++) {
          for (int dy = 0; dy < 2; dy++) {
            for (int ox = 0; ox < 2; ox++) {
              for (int oy = 0; oy < 2; oy++) {
                final px = x + dx + ox;
                final py = y + dy + oy;
                if (tileManager.isTileOccupied(px, py)) {
                  canPlaceGroup = false;
                  break;
                }
              }
            }
          }
        }

        if (canPlaceGroup) {
          for (int dx = 0; dx <= 2; dx += 2) {
            for (int dy = 0; dy <= 2; dy += 2) {
              await _addBigDecoration(x + dx, y + dy, group['image'] as String);
            }
          }
          placed++;
        }
      }
    }
  }

  Future<void> _addBigDecoration(int x, int y, String imagePath) async {
    if (tileManager.isOccupied(x, y, 2, 2)) return;
    tileManager.occupy(x, y, 2, 2);

    final sprite = await Sprite.load(imagePath);
    add(SpriteComponent()
      ..sprite = sprite
      ..size = Vector2(tileSize * 2, tileSize * 2)
      ..position = Vector2(x * tileSize, y * tileSize)
      ..priority = 10);
  }

  List<List<MapStyle>> _generateVoronoiTiles() {
    final rand = Random(currentFloor);
    final allStyles = MapStyle.values.toList()..shuffle(rand);
    final selectedStyles = allStyles.take(4).toList();
    final seeds = <Point<int>, MapStyle>{};

    for (int i = 0; i < 20; i++) {
      final px = rand.nextInt(cols);
      final py = rand.nextInt(rows);
      final style = selectedStyles[rand.nextInt(selectedStyles.length)];
      seeds[Point(px, py)] = style;
    }

    final grid = List.generate(rows, (_) => List.filled(cols, MapStyle.grass));

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (tileManager.isTileOccupied(x, y)) continue;
        double minDist = double.infinity;
        MapStyle? closestStyle;

        for (final entry in seeds.entries) {
          final dx = x - entry.key.x;
          final dy = y - entry.key.y;
          final dist = (dx * dx + dy * dy).toDouble();

          if (dist < minDist) {
            minDist = dist;
            closestStyle = entry.value;
          }
        }

        grid[y][x] = closestStyle!;
        if (closestStyle == MapStyle.lava || closestStyle == MapStyle.mud) {
          bossCandidateTiles.add(Point(x, y));
        }
      }
    }

    return grid;
  }

  Point<int>? getBossSpawnPoint(Vector2 entry) {
    if (bossCandidateTiles.isEmpty) return null;
    bossCandidateTiles.sort((a, b) {
      final d1 = (a.x - entry.x).abs() + (a.y - entry.y).abs();
      final d2 = (b.x - entry.x).abs() + (b.y - entry.y).abs();
      return d2.compareTo(d1);
    });
    return bossCandidateTiles.first;
  }

  void buildGrid() {
    _grid = List.generate(rows, (y) {
      return List.generate(cols, (x) {
        return tileManager.isTileOccupied(x, y) ? 0 : 1;
      });
    });
  }

  List<List<int>> get grid => _grid;
}