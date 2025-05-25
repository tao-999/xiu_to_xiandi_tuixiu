import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/game/path_finder.dart';

class WorldMapImageView extends StatefulWidget {
  final EdgeInsets safePadding;
  const WorldMapImageView({super.key, required this.safePadding});

  @override
  State<WorldMapImageView> createState() => _WorldMapImageViewState();
}

class _WorldMapImageViewState extends State<WorldMapImageView> {
  late final FreeMapGame _game;

  @override
  void initState() {
    super.initState();
    _game = FreeMapGame(safePadding: widget.safePadding);
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: _game);
  }
}

class FreeMapGame extends FlameGame with TapCallbacks {
  final EdgeInsets safePadding;
  FreeMapGame({required this.safePadding});

  final double mapWidth = 3000;
  final double mapHeight = 3000;
  final double tileSize = 50.0;

  late final int rows, cols;
  late final PathFinder pathFinder;

  late final PlayerComponent player;
  late final CameraComponent cameraComponent;
  late final World world;

  Vector2 clampTarget(Vector2 raw) {
    const margin = 5.0;
    return Vector2(
      raw.x.clamp(tileSize / 2 + margin, mapWidth - tileSize / 2 - margin),
      raw.y.clamp(tileSize / 2 + margin, mapHeight - tileSize / 2 - margin),
    );
  }

  @override
  Future<void> onLoad() async {
    final screenSize = ui.window.physicalSize / ui.window.devicePixelRatio;
    rows = (mapHeight / tileSize).floor();
    cols = (mapWidth / tileSize).floor();

    world = World();
    add(world);

    // 背景底色
    world.add(RectangleComponent(
      size: Vector2(mapWidth, mapHeight),
      paint: Paint()..color = const Color(0xFF444444),
    ));

    final random = Random();
    const List<String> emojis = ['🪨', '🌲', '🧱'];
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => false));

    for (int i = 0; i < 1200; i++) {
      final r = random.nextInt(rows);
      final c = random.nextInt(cols);

      if ((r - rows ~/ 2).abs() < 3 && (c - cols ~/ 2).abs() < 3) continue;
      if (grid[r][c]) continue;

      grid[r][c] = true;
      final pos = Vector2(c * tileSize, r * tileSize);

      world.add(TextComponent(
        text: emojis[random.nextInt(emojis.length)],
        position: pos,
        anchor: Anchor.topLeft,
        textRenderer: TextPaint(
          style: TextStyle(fontSize: tileSize * 0.9),
        ),
        priority: 200,
      ));
    }

    player = PlayerComponent()
      ..position = Vector2(mapWidth / 2, mapHeight / 2);
    world.add(player);

    cameraComponent = CameraComponent.withFixedResolution(
      world: world,
      width: screenSize.width,
      height: screenSize.height,
    )
      ..viewfinder.anchor = Anchor.center
      ..follow(player)
      ..setBounds(
        Rectangle.fromLTWH(0, 0, mapWidth, mapHeight),
        considerViewport: true,
      );
    add(cameraComponent);

    pathFinder = PathFinder(grid: grid, tileSize: tileSize);
    _addEmojiBorder();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final worldPos = cameraComponent.viewfinder.globalToLocal(event.canvasPosition);
    final safeTarget = clampTarget(worldPos);

    final path = pathFinder.findPath(player.position, safeTarget);

    if (path.isEmpty) {
      debugPrint('骚哥你点的地方被灵气封印了，走不动 ❌');
      return;
    }

    _movePlayerAlong(path);
  }

  void _movePlayerAlong(List<Vector2> path) {
    if (path.isEmpty) return;

    void walkStep(int index) {
      if (index >= path.length) return;
      player.target = path[index];

      final duration = ((path[index] - player.position).length / player.speed * 1000).toInt();
      Future.delayed(Duration(milliseconds: duration), () => walkStep(index + 1));
    }

    walkStep(0);
  }

  void _addEmojiBorder() {
    const emoji = '🧱';
    const spacing = 40.0;
    final countX = (mapWidth / spacing).ceil();
    final countY = (mapHeight / spacing).ceil();

    for (int i = 0; i <= countX; i++) {
      world.add(TextComponent(
        text: emoji,
        position: Vector2(i * spacing, 0),
        anchor: Anchor.center,
        priority: 1000,
      ));
      world.add(TextComponent(
        text: emoji,
        position: Vector2(i * spacing, mapHeight),
        anchor: Anchor.center,
        priority: 1000,
      ));
    }

    for (int j = 0; j <= countY; j++) {
      world.add(TextComponent(
        text: emoji,
        position: Vector2(0, j * spacing),
        anchor: Anchor.center,
        priority: 1000,
      ));
      world.add(TextComponent(
        text: emoji,
        position: Vector2(mapWidth, j * spacing),
        anchor: Anchor.center,
        priority: 1000,
      ));
    }
  }
}
