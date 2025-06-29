import 'dart:math';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/experimental.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';

import '../effects/lightning_effect_component.dart';
import 'hell_monster_component.dart';
import 'hell_player_component.dart';
import 'safe_zone_circle.dart';
import 'hell_level_overlay.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/monster_wave_info.dart';

class YoumingHellMapGame extends FlameGame with HasCollisionDetection, WidgetsBindingObserver {
  final BuildContext context;
  int level;

  late final World world;
  late final CameraComponent cameraComponent;
  late final PositionComponent mapRoot;
  late final HellPlayerComponent player;

  final Map<int, Sprite> tileSprites = {};
  late Vector2 safeZoneCenter;
  final double safeZoneRadius = 64;

  final int monstersPerWave = 50;
  final int totalWaves = 3;
  int currentWave = 1;
  final Map<int, List<HellMonsterComponent>> waves = {};

  double _lightningTimer = 3.0; // 冷却计时器
  bool _waveFinished = false;
  bool _hasPassed = false;
  bool _hasJustLoaded = false;

  late MonsterWaveInfo monsterWaveInfo;

  YoumingHellMapGame(this.context, {this.level = 1});

  @override
  Future<void> onLoad() async {
    add(FpsTextComponent());
    WidgetsBinding.instance.addObserver(this);
    await _initCameraAndWorld();

    final bgSprite = await Sprite.load('hell/diyu_tile.webp');
    mapRoot.add(HellMapBackground(bgSprite));

    _addInteractionLayer();

    // ✅先创建UI
    monsterWaveInfo = MonsterWaveInfo(
      gameRef: this,
      waves: waves,
      currentWave: currentWave,
      totalWaves: totalWaves,
      currentAlive: monstersPerWave + 1,
    );

    cameraComponent.viewport.add(monsterWaveInfo);
    cameraComponent.viewport.add(HellLevelOverlay(getLevel: () => level));

    final saved = await _loadSave();
    if (saved != null) {
      level = saved['level'];
      await _spawnPlayer(fromSave: saved['player']);
      await _restoreWavesFromSave(saved['monsters']);
      currentWave = saved['currentWave'];
    } else {
      await _spawnPlayer();
      await _generateAllWaves();
      currentWave = 1;
    }

    _addSafeZone();
    _loadWave(currentWave);
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

  void checkWaveProgress() {
    final alive = getAliveMonsterCount(currentWave);

    monsterWaveInfo.updateInfo(
      waveIndex: currentWave,
      waveTotal: totalWaves,
      alive: alive,
      total: monstersPerWave,
    );

    if (alive == 0 && !_waveFinished) {
      _waveFinished = true;

      if (currentWave < totalWaves) {
        currentWave += 1;
        _loadWave(currentWave);
        _waveFinished = false;
      } else {
        _onHellCleared();
      }
    }
  }

  void _onHellCleared() {
    final star = mapRoot.children.whereType<SafeZoneCircle>().firstOrNull;
    star?.startGlow();
  }

  void _fireLightning() {
    final rect = cameraComponent.visibleWorldRect;
    final random = math.Random();
    final actualCount = random.nextInt(3) + 1;

    for (int i = 0; i < actualCount; i++) {
      final start = Vector2(
        rect.left + random.nextDouble() * rect.width,
        rect.top + random.nextDouble() * rect.height,
      );
      final angle = random.nextDouble() * 2 * math.pi;
      final dir = Vector2(math.cos(angle), math.sin(angle));
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
    final toRemove = List<SafeZoneCircle>.from(mapRoot.children.whereType<SafeZoneCircle>());
    for (final c in toRemove) {
      c.removeFromParent();
    }

    mapRoot.add(SafeZoneCircle(
      center: safeZoneCenter,
      radius: safeZoneRadius,
    ));
  }

  int getAliveMonsterCount(int wave) {
    return waves[wave]?.where((m) => m.hp > 0 && m.parent != null).length ?? 0;
  }

  Future<void> _spawnPlayer({Map<String, dynamic>? fromSave}) async {
    safeZoneCenter = Vector2(mapRoot.size.x / 2, mapRoot.size.y / 2);

    player = HellPlayerComponent(
      safeZoneCenter: safeZoneCenter,
      safeZoneRadius: safeZoneRadius,
      onRevived: () => cameraComponent.follow(player),
      onHellPassed: _handleHellPassed,
      isWaveCleared: () {
        final alive = getAliveMonsterCount(currentWave);
        return currentWave > totalWaves || alive == 0;
      },
    )..position = fromSave != null
        ? Vector2(fromSave['x'], fromSave['y'])
        : safeZoneCenter.clone();

    mapRoot.add(player);
    cameraComponent.follow(player);
    cameraComponent.setBounds(
      Rectangle.fromPoints(Vector2.zero(), mapRoot.size.clone()),
      considerViewport: true,
    );

    mapRoot.add(SafeZoneCircle(
      center: safeZoneCenter,
      radius: safeZoneRadius,
    ));
  }

  void _handleHellPassed() {
    if (_hasPassed || _hasJustLoaded) return;
    _hasPassed = true;

    level += 1;

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hell_save', jsonEncode({
        'level': level,
        'currentWave': 1,
        'player': {
          'x': mapRoot.size.x / 2,
          'y': mapRoot.size.y / 2,
          'hp': player.maxHp,
        },
        'monsters': [],
      }));

      _hasPassed = false;
      _hasJustLoaded = true;
      _restartHellLevel();

      Future.delayed(const Duration(seconds: 1), () {
        _hasJustLoaded = false;
      });
    });
  }

  Future<void> _restartHellLevel() async {
    for (final monsters in waves.values) {
      for (final m in monsters) {
        m.removeFromParent();
      }
    }
    waves.clear();
    currentWave = 1;
    _waveFinished = false;

    monsterWaveInfo.updateInfo(
      waveIndex: currentWave,
      waveTotal: totalWaves,
      alive: 0,
      total: monstersPerWave,
    );

    player.hp = player.maxHp;
    player.position = safeZoneCenter.clone();
    cameraComponent.follow(player);

    _addSafeZone();

    await _generateAllWaves();
    _loadWave(currentWave);

    await saveCurrentState();
  }

  Future<void> _generateAllWaves() async {
    final rng = Random(level);
    waves.clear();
    int monsterId = 0;

    for (int wave = 1; wave <= totalWaves; wave++) {
      final List<HellMonsterComponent> waveMonsters = [];
      final monsterSpeed = (40 + wave * 15).toDouble();
      final bossSpeed = (60 + wave * 15).toDouble();

      for (int i = 0; i < monstersPerWave; i++) {
        final pos = _getValidSpawnPosition(rng);
        final monster = HellMonsterComponent(
          id: monsterId++,
          level: level,
          isBoss: false,
          waveIndex: wave,
          position: pos,
        )..priority = 10;

        monster.trackTarget(
          player,
          speed: monsterSpeed,
          safeCenter: safeZoneCenter,
          safeRadius: safeZoneRadius,
        );

        waveMonsters.add(monster);
      }

      final bossPos = _getBossSpawnPosition(rng);
      final boss = HellMonsterComponent(
        id: monsterId++,
        level: level,
        isBoss: true,
        waveIndex: wave,
        position: bossPos,
      )..priority = 10;

      boss.trackTarget(
        player,
        speed: bossSpeed,
        safeCenter: safeZoneCenter,
        safeRadius: safeZoneRadius,
      );

      waveMonsters.add(boss);
      waves[wave] = waveMonsters;
    }
  }

  void _loadWave(int waveIndex) {
    if (waveIndex < 1) waveIndex = 1;
    if (waveIndex > totalWaves) return;

    final waveEmpty = !waves.containsKey(waveIndex) || waves[waveIndex]!.isEmpty;
    if (waveEmpty) {
      _loadWave(waveIndex + 1);
      return;
    }

    currentWave = waveIndex;
    for (final monster in waves[currentWave]!) {
      mapRoot.add(monster);
    }
    _waveFinished = false;
    checkWaveProgress();
  }

  Vector2 _getValidSpawnPosition(Random rng) {
    final radius = safeZoneRadius + 100 + rng.nextDouble() * 500;
    final angle = rng.nextDouble() * 2 * pi;
    final pos = safeZoneCenter + Vector2(
      cos(angle) * radius,
      sin(angle) * radius,
    );
    return Vector2(
      pos.x.clamp(0, mapRoot.size.x),
      pos.y.clamp(0, mapRoot.size.y),
    );
  }

  Vector2 _getBossSpawnPosition(Random rng) {
    final radius = safeZoneRadius + 300 + rng.nextDouble() * 200;
    final angle = rng.nextDouble() * 2 * pi;
    final pos = safeZoneCenter + Vector2(
      cos(angle) * radius,
      sin(angle) * radius,
    );
    return Vector2(
      pos.x.clamp(0, mapRoot.size.x),
      pos.y.clamp(0, mapRoot.size.y),
    );
  }

  Future<void> _restoreWavesFromSave(List<dynamic> savedList) async {
    waves.clear();
    final grouped = <int, List<HellMonsterComponent>>{};

    for (final raw in savedList) {
      final waveIndex = raw['waveIndex'];
      final monster = HellMonsterComponent(
        id: raw['id'],
        level: raw['level'],
        isBoss: raw['isBoss'],
        waveIndex: waveIndex,
        position: Vector2(raw['x'], raw['y']),
      )..priority = 10;

      monster.hp = raw['hp'];
      monster.maxHp = raw['maxHp'];
      monster.atk = raw['atk'];
      monster.def = raw['def'];

      monster.trackTarget(
        player,
        speed: monster.isBoss ? 60 : 30,
        safeCenter: safeZoneCenter,
        safeRadius: safeZoneRadius,
      );

      grouped.putIfAbsent(waveIndex, () => []).add(monster);
    }

    for (final entry in grouped.entries) {
      waves[entry.key] = entry.value;
    }
  }

  Future<void> saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    final playerMap = {
      'x': player.position.x,
      'y': player.position.y,
      'hp': player.hp,
    };

    final monsterList = waves.entries
        .expand((entry) => entry.value)
        .where((m) => m.hp > 0)
        .map((m) => {
      'id': m.id,
      'x': m.position.x,
      'y': m.position.y,
      'hp': m.hp,
      'waveIndex': m.waveIndex,
      'isBoss': m.isBoss,
      'level': m.level,
      'atk': m.atk,
      'def': m.def,
      'maxHp': m.maxHp,
    })
        .toList();

    final state = {
      'level': level,
      'currentWave': currentWave,
      'player': playerMap,
      'monsters': monsterList,
    };

    await prefs.setString('hell_save', jsonEncode(state));
  }

  Future<Map<String, dynamic>?> _loadSave() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hell_save');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (e) {
      return null;
    }
  }

  @override
  Color backgroundColor() => Colors.black;
}

class HellMapBackground extends Component {
  final Sprite sprite;
  HellMapBackground(this.sprite);

  @override
  void render(Canvas canvas) {
    sprite.render(
      canvas,
      size: Vector2(1024, 1024),
      anchor: Anchor.topLeft,
    );
  }

  @override
  void update(double dt) {}
}
