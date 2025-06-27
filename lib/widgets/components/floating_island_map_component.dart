import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_grid_painter_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/floating_island_player_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/floating_island_storage.dart';
import 'package:flutter/widgets.dart'; // 👈 别忘了

class FloatingIslandMapComponent extends FlameGame with WidgetsBindingObserver {
  late final DragMap _dragMap;
  late final InfiniteGridPainterComponent _grid;
  FloatingIslandPlayerComponent? player;

  Vector2 cameraOffset = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    WidgetsBinding.instance.addObserver(this);
    print('[FloatingIslandMap] onLoad started.');

    _grid = InfiniteGridPainterComponent();
    print('[FloatingIslandMap] Grid created.');

    _dragMap = DragMap(
      onDragged: (delta) {
        cameraOffset += delta;
        _grid.position = cameraOffset.clone();
        print('[FloatingIslandMap] Dragged: cameraOffset=$cameraOffset');
      },
      onTap: (tapPos) {
        final worldPos = tapPos - _grid.position;
        player?.moveTo(worldPos);
        print('[FloatingIslandMap] Tap to move: $worldPos');
      },
      showGrid: false,
      childBuilder: () => _grid,
    );

    add(_dragMap);
    print('[FloatingIslandMap] DragMap added.');

    await Future.delayed(Duration.zero);

    // ⬇️ 加载存储
    final pos = await FloatingIslandStorage.getPlayerPosition();
    final cam = await FloatingIslandStorage.getCameraOffset();

    // ⬇️ 设置初始偏移
    if (cam != null) {
      cameraOffset = Vector2(cam['x']!, cam['y']!);
      print('[FloatingIslandMap] Loaded camera offset: $cameraOffset');
    } else {
      cameraOffset = size / 2;
      print('[FloatingIslandMap] Default camera offset: $cameraOffset');
    }
    _grid.position = cameraOffset.clone();

    // ⬇️ 创建玩家（挂监听）
    player = FloatingIslandPlayerComponent(
      onPositionChanged: (p) {
        cameraOffset = size / 2 - p;
        _grid.position = cameraOffset.clone();
        print('[FloatingIslandMap] Player moved: cameraOffset=$cameraOffset');
      },
    )..anchor = Anchor.center;

    // ⬇️ 先添加到grid
    _grid.add(player!);
    print('[FloatingIslandMap] Player added.');

    // ⬇️ 下一帧再赋值位置（避免立即触发回调）
    if (pos != null) {
      Future.microtask(() {
        player!.position = Vector2(pos['x']!, pos['y']!);
        print('[FloatingIslandMap] Loaded player position (deferred): ${player!.position}');
      });
    } else {
      Future.microtask(() {
        player!.position = Vector2.zero();
        print('[FloatingIslandMap] Default player position (deferred): ${player!.position}');
      });
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _grid
      ..viewScale = 1.0
      ..viewSize = size.clone();
  }

  /// 保存当前状态
  Future<void> saveState() async {
    if (player != null) {
      await FloatingIslandStorage.savePlayerPosition(
        player!.x,
        player!.y,
      );
    }
    await FloatingIslandStorage.saveCameraOffset(
      cameraOffset.x,
      cameraOffset.y,
    );
  }

  @override
  void onRemove() {
    // 移除监听
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      saveState();
    }
  }

  void resetToCenter() {
    cameraOffset = size / 2;
    _grid.position = cameraOffset.clone();
  }
}
