// 📂 lib/widgets/components/huanyue_door_component.dart

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:xiu_to_xiandi_tuixiu/services/huanyue_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/tile_manager.dart';

typedef VoidCallback = void Function();

class HuanyueDoorComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  final double tileSize;
  final VoidCallback? onEnterDoor;
  final List<List<int>> grid;
  final int maxAttempts;
  final int currentFloor;
  final TileManager tileManager;

  /// 🌟 距离地图边缘最少多少像素
  final double margin;

  HuanyueDoorComponent({
    required this.tileSize,
    required this.grid,
    required this.currentFloor,
    required this.tileManager,
    this.onEnterDoor,
    this.maxAttempts = 100,
    this.margin = 50.0,
  }) : super(
    size: Vector2.all(64),
    anchor: Anchor.center,
    priority: 20,
  );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('huanyue/tietu_men.png');
    await _spawnDoor();

    add(RectangleHitbox()..collisionType = CollisionType.passive);
    print('✅门sprite: $sprite');
  }

  Future<void> _spawnDoor() async {
    final saved = await HuanyueStorage.getDoorPosition(currentFloor);
    if (saved != null && saved != Vector2.zero()) {
      position = saved;
      return;
    }

    final rows = grid.length;
    final cols = grid[0].length;
    final rand = Random();

    // 🟢 计算margin在tile坐标下
    final marginTiles = (margin / tileSize).ceil();
    const areaSize = 2;

    // 🌟 确保不会越界
    final minX = marginTiles;
    final maxX = cols - areaSize - marginTiles;
    final minY = marginTiles;
    final maxY = rows - areaSize - marginTiles;

    for (int i = 0; i < maxAttempts; i++) {
      final x = rand.nextInt(maxX - minX + 1) + minX;
      final y = rand.nextInt(maxY - minY + 1) + minY;

      bool canPlace = true;
      for (int dx = 0; dx < areaSize; dx++) {
        for (int dy = 0; dy < areaSize; dy++) {
          final tx = x + dx;
          final ty = y + dy;
          if (grid[ty][tx] == 0 || tileManager.isTileOccupied(tx, ty)) {
            canPlace = false;
            break;
          }
        }
        if (!canPlace) break;
      }

      if (canPlace) {
        final pos = Vector2(
          (x + areaSize / 2) * tileSize,
          (y + areaSize / 2) * tileSize,
        );
        position = pos;
        await HuanyueStorage.saveDoorPosition(currentFloor, pos);

        tileManager.occupy(x, y, areaSize, areaSize);
        return;
      }
    }

    // fallback: 中心点
    final fallback = Vector2(cols * tileSize / 2, rows * tileSize / 2);
    position = fallback;
    await HuanyueStorage.saveDoorPosition(currentFloor, fallback);
    print('🌟门最终位置: $position');
  }

  bool isPlayerAtDoor(Vector2 playerPos) {
    final dist = (playerPos - position).length;
    return dist < tileSize * 1.5;
  }

  void onPlayerEnter() {
    if (onEnterDoor != null) onEnterDoor!();
  }

  Vector2 get gridPosition => Vector2(
    (position.x / tileSize).floorToDouble(),
    (position.y / tileSize).floorToDouble(),
  );
}
