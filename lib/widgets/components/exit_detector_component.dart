import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/services/maze_storage.dart';
import 'maze_player_component.dart';

class ExitDetectorComponent extends Component with HasGameRef {
  final Vector2 exitTile;
  final double tileSize;
  final int currentFloor;
  final VoidCallback onNextFloor;

  bool _triggered = false;

  ExitDetectorComponent({
    required this.exitTile,
    required this.tileSize,
    required this.currentFloor,
    required this.onNextFloor,
  });

  @override
  void update(double dt) async {
    if (_triggered) return;

    final player = gameRef.descendants().whereType<MazePlayerComponent>().firstOrNull;
    if (player == null) return;

    final pos = player.gridPosition;
    final isAtExit = pos == exitTile;
    if (!isAtExit) return;

    final enemies = await MazeStorage.loadEnemyStates();
    final killedIds = await MazeStorage.getKilledEnemyIds();

    // ✅ 用 UUID 判断剩余敌人
    final remaining = enemies?.where((e) => !killedIds.contains(e.id)).toList() ?? [];

    final chestOpened = await MazeStorage.getChestOpened();
    final needsChest = currentFloor % 5 == 0;

    print("🧟‍♂️ 剩余敌人：${remaining.length}，宝箱开启：$chestOpened");

    if (remaining.isEmpty && (!needsChest || chestOpened)) {
      print('🎯 满足通关条件，进入第 ${currentFloor + 1} 层！');
      _triggered = true;
      onNextFloor();
    }
  }
}
