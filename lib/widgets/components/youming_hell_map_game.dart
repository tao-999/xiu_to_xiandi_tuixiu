import 'dart:math';
import 'package:flame/experimental.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';

import '../effects/lightning_effect_component.dart';
import 'hell_player_component.dart';
import 'safe_zone_circle.dart';
import 'hell_level_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/monster_wave_info.dart';
import '../../services/hell_service.dart';
import 'hell_monster_manager.dart';
import 'hell_monster_component.dart';

class YoumingHellMapGame extends FlameGame with HasCollisionDetection, WidgetsBindingObserver {
  final BuildContext context;
  int level;

  late final World world;
  late final CameraComponent cameraComponent;
  late final PositionComponent mapRoot;
  late final HellPlayerComponent player;
  late final HellMonsterManager monsterManager;

  final Map<int, Sprite> tileSprites = {};
  late final Vector2 safeZoneCenter;
  final double safeZoneRadius = 64;

  static const int monstersTotal = 100;

  double _lightningTimer = 3.0;
  bool _hasPassed = false;
  bool _hasJustLoaded = false;

  late MonsterWaveInfo monsterWaveInfo;

  YoumingHellMapGame(this.context, {this.level = 1});

  @override
  Future<void> onLoad() async {
    add(FpsTextComponent()
      ..anchor = Anchor.topLeft
      ..position = Vector2(10, 10));

    WidgetsBinding.instance.addObserver(this);
    await _initCameraAndWorld();

    final bgSprite = await Sprite.load('hell/diyu_tile.webp');
    mapRoot.add(HellMapBackground(bgSprite));

    _addInteractionLayer();

    monsterWaveInfo = MonsterWaveInfo(
      gameRef: this,
      currentTotal: monstersTotal + 1,
    );
    cameraComponent.viewport.addAll([
      monsterWaveInfo,
      HellLevelOverlay(getLevel: () => level),
    ]);

    safeZoneCenter = mapRoot.size / 2;

    await _spawnPlayer();

    monsterManager = HellMonsterManager(
      level: level,
      totalCount: monstersTotal,
      mapRoot: mapRoot,
      player: player,
      safeZoneCenter: safeZoneCenter,
      safeZoneRadius: safeZoneRadius,
      monsterWaveInfo: monsterWaveInfo,
    );

    await monsterManager.initMonsters(); // 🧠 由 manager 自己决定是否恢复或新建

    _addSafeZone();
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      saveCurrentState();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lightningTimer -= dt;
    if (_lightningTimer <= 0) {
      _fireLightning();
      _lightningTimer = 3.0;
    }
  }

  void onHellCleared() {
    final star = mapRoot.children.whereType<SafeZoneCircle>().firstOrNull;
    star?.startGlow();
  }

  void _fireLightning() {
    final rect = cameraComponent.visibleWorldRect;
    final random = Random();
    final actualCount = random.nextInt(3) + 1;
    for (int i = 0; i < actualCount; i++) {
      final start = Vector2(
        rect.left + random.nextDouble() * rect.width,
        rect.top + random.nextDouble() * rect.height,
      );
      final angle = random.nextDouble() * 2 * pi;
      final dir = Vector2(cos(angle), sin(angle));
      final maxDistance = 200 + random.nextDouble() * 300;
      mapRoot.add(LightningEffectComponent(
        start: start,
        direction: dir,
        maxDistance: maxDistance,
      ));
    }
  }

  Future<void> _initCameraAndWorld() async {
    mapRoot = PositionComponent(
      size: Vector2(1024, 1024),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );
    world = World()..add(mapRoot);
    cameraComponent = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );
    addAll([world, cameraComponent]);
  }

  void _addInteractionLayer() {
    add(DragMap(
      onDragged: _handleDrag,
      onTap: _handleTap,
    ));
  }

  void _handleDrag(Vector2 delta) {
    cameraComponent.stop();
    cameraComponent.moveBy(-delta);
  }

  void _handleTap(Vector2 canvasPosition) {
    final worldPos = cameraComponent.globalToLocal(canvasPosition);
    player.moveTo(worldPos);
    cameraComponent.follow(player);
  }

  void _addSafeZone() {
    mapRoot.children.whereType<SafeZoneCircle>().forEach((c) => c.removeFromParent());
    mapRoot.add(SafeZoneCircle(
      center: safeZoneCenter,
      radius: safeZoneRadius,
    ));
  }

  Future<void> _spawnPlayer() async {
    final info = await HellService.loadPlayerInfo();

    // 如果有存档，从存档加载；否则用默认中心点
    final startPos = info != null
        ? Vector2(info['x'], info['y'])
        : safeZoneCenter.clone();

    level = info?['level'] ?? level;

    player = HellPlayerComponent(
      safeZoneCenter: safeZoneCenter,
      safeZoneRadius: safeZoneRadius,
      onRevived: () => cameraComponent.follow(player),
      onHellPassed: _handleHellPassed,
      isWaveCleared: () => monsterManager.isBossSpawned && (monsterManager.bossMonster?.hp ?? 1) <= 0,
    )..position = startPos;

    if (info != null) {
      player.hp = info['hp'];
      player.maxHp = info['maxHp'];
    }

    mapRoot.add(player);
    cameraComponent.follow(player);
    cameraComponent.setBounds(
      Rectangle.fromPoints(Vector2.zero(), mapRoot.size.clone()),
      considerViewport: true,
    );
  }

  void _handleHellPassed() {
    if (_hasPassed || _hasJustLoaded) return;
    _hasPassed = true;
    level += 1;

    Future.microtask(() async {
      await HellService.saveState(killed: 0, bossSpawned: false, spawned: 0);
      await HellService.clearAll(); // 全部清空状态
      _hasPassed = false;
      _hasJustLoaded = true;
      _restartHellLevel();
      Future.delayed(const Duration(seconds: 1), () {
        _hasJustLoaded = false;
      });
    });
  }

  Future<void> _restartHellLevel() async {
    await monsterManager.reset();
    await monsterManager.initMonsters();

    player.hp = player.maxHp;
    player.position = safeZoneCenter.clone();
    cameraComponent.follow(player);
    _addSafeZone();

    await saveCurrentState();
  }

  Future<void> saveCurrentState() async {
    await HellService.saveState(
      killed: monsterManager.killedCount,
      bossSpawned: monsterManager.isBossSpawned,
      spawned: monsterManager.spawnedCount, // 👈 新增这行
    );

    final alive = mapRoot.children
        .whereType<HellMonsterComponent>()
        .where((m) => !m.isBoss)
        .toList();

    await HellService.saveAliveMonsters(alive);

    if (monsterManager.bossMonster != null && monsterManager.bossMonster!.isMounted) {
      await HellService.saveBossMonster(monsterManager.bossMonster!);
    }

    await HellService.savePlayerInfo(
      position: player.position,
      hp: player.hp,
      maxHp: player.maxHp,
      level: level,
    );

    debugPrint('💾 [HellGame] 状态已保存（包含玩家、怪物、boss）');
  }

  @override
  Color backgroundColor() => Colors.black;
}

class HellMapBackground extends Component {
  final Sprite sprite;
  HellMapBackground(this.sprite);

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: Vector2(1024, 1024), anchor: Anchor.topLeft);
  }

  @override
  void update(double dt) {}
}
