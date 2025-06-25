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

  static const int tileSize = 32;
  static const int mapSize = 64;

  late final World world;
  late final CameraComponent cameraComponent;
  late final PositionComponent mapRoot;
  late final HellPlayerComponent player;

  final Map<int, Sprite> tileSprites = {};
  late Vector2 safeZoneCenter;
  final double safeZoneRadius = 64;

  final int monstersPerWave = 100;
  final int totalWaves = 3;
  int currentWave = 1;
  final Map<int, List<HellMonsterComponent>> waves = {};

  double _lightningCooldown = 0.0;
  bool _isReleasingLightning = false;

  late MonsterWaveInfo monsterWaveInfo;
  bool _waveFinished = false;
  bool _hasPassed = false;
  bool _hasJustLoaded = false;

  YoumingHellMapGame(this.context, {this.level = 1});

  @override
  Future<void> onLoad() async {
    WidgetsBinding.instance.addObserver(this);
    await _initCameraAndWorld();
    await _loadTileSprites();
    _generateTileMap();
    _addInteractionLayer();

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

    // ✅ 每次加载完玩家后重新挂载安全区，避免旧 SafeZoneCircle 留下回调陷阱
    _addSafeZone();

    _loadWave(currentWave);

    monsterWaveInfo = MonsterWaveInfo(
      currentWave: currentWave,
      totalWaves: totalWaves,
      currentAlive: monstersPerWave + 1,
    );

    cameraComponent.viewport.add(monsterWaveInfo);
    cameraComponent.viewport.add(HellLevelOverlay(getLevel: () => level));
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

    _lightningCooldown -= dt;
    if (_lightningCooldown <= 0 && !_isReleasingLightning) {
      _isReleasingLightning = true;
      _fireLightning().then((_) {
        _lightningCooldown = 1.0;
        _isReleasingLightning = false;
      });
    }

    final alive = getAliveMonsterCount(currentWave);
    monsterWaveInfo.updateInfo(
      waveIndex: currentWave,
      waveTotal: totalWaves,
      alive: alive,
    );
  }

  void checkWaveProgress() {
    print('\n🧠 [checkWaveProgress] ========================');
    print('📍 当前波次: $currentWave');
    print('📦 当前波次是否存在: ${waves.containsKey(currentWave)}');
    print('👾 当前波怪物总数: ${waves[currentWave]?.length ?? 0}');
    final alive = getAliveMonsterCount(currentWave);
    print('💀 当前波挂载怪物剩余: $alive');
    print('📍 _waveFinished 标记状态: $_waveFinished');

    if (alive == 0 && !_waveFinished) {
      print('✅ [checkWaveProgress] 当前波怪物清空，准备进入下一波');

      _waveFinished = true;

      if (currentWave < totalWaves) {
        Future.delayed(const Duration(seconds: 1), () {
          currentWave += 1;
          print('⏭️ 正在加载下一波: $currentWave');
          _loadWave(currentWave);
          _waveFinished = false;
        });
      } else {
        print('🏁 所有波次已完成，胜利🎉');
        _onHellCleared();
      }
    } else {
      print('⏸️ 还有怪物活着，或者 _waveFinished 已被标记，不触发加载');
    }

    print('🔚 [checkWaveProgress] ========================\n');
  }

  void _onHellCleared() {
    print('✨ 地狱已通关，安全区开始发光');

    // ✅ 假设你有个安全区组件
    final star = mapRoot.children.whereType<SafeZoneCircle>().firstOrNull;
    star?.startGlow(); // ✅ 触发发光（你自己定义）
  }

  Future<void> _fireLightning() async {
    final rect = cameraComponent.visibleWorldRect;
    final random = math.Random();
    final actualCount = random.nextInt(10) + 1;

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

      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> _initCameraAndWorld() async {
    mapRoot = PositionComponent(
      size: Vector2(tileSize * mapSize.toDouble(), tileSize * mapSize.toDouble()),
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

  Future<void> _loadTileSprites() async {
    for (int i = 1; i <= 9; i++) {
      tileSprites[i] = await loadSprite('hell/diyu_tile_$i.webp');
    }
  }

  void _generateTileMap() {
    final rng = Random(level);
    final weighted = [
      ...Iterable.generate(16, (_) => 1),
      ...Iterable.generate(10, (_) => 2),
      ...Iterable.generate(7, (_) => 3),
      4, 4, 5, 5, 6, 7, 8, 9
    ];

    for (int row = 0; row < mapSize; row++) {
      for (int col = 0; col < mapSize; col++) {
        final spr = tileSprites[weighted[rng.nextInt(weighted.length)]]!;
        mapRoot.add(SpriteComponent(
          sprite: spr,
          size: Vector2.all(tileSize.toDouble()),
          position: Vector2(col * tileSize.toDouble(), row * tileSize.toDouble()),
          anchor: Anchor.topLeft,
        ));
      }
    }
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
    // ✅ 先复制，避免遍历中修改原集合导致异常
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

    // ✅ 打印出生坐标（无论是否来自存档）
    print('🎯 玩家加载完成，出生坐标: ${player.position}');
  }

  void _handleHellPassed() {
    if (_hasPassed || _hasJustLoaded) return;
    _hasPassed = true;

    print('🌀 玩家进入安全区，准备进入下一层');

    Future.delayed(const Duration(milliseconds: 300), () async {
      level += 1;

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
      _hasJustLoaded = true; // ✅ 标记刚进入新层，禁止立刻触发升层
      _restartHellLevel();

      // ✅ 1秒后解除标记，允许再次升层
      Future.delayed(const Duration(seconds: 1), () {
        _hasJustLoaded = false;
        print('🟢 允许下一次安全区通关触发');
      });
    });
  }

  Future<void> _restartHellLevel() async {
    print('🌋 正在初始化第 $level 层新地狱...');

    // 清空波次数据和怪物
    for (final monsters in waves.values) {
      for (final m in monsters) {
        m.removeFromParent();
      }
    }
    waves.clear();
    currentWave = 1;
    _waveFinished = false;

    // 清空 UI 状态
    monsterWaveInfo.updateInfo(
      waveIndex: currentWave,
      waveTotal: totalWaves,
      alive: 0,
    );

    // 重置玩家状态
    player.hp = player.maxHp;
    player.position = safeZoneCenter.clone();
    cameraComponent.follow(player);

    // ✅ 重新挂载新的安全区组件，移除旧的，避免继续触发 onHellPassed
    _addSafeZone();

    // 重新生成怪物
    await _generateAllWaves();
    _loadWave(currentWave);

    // 存档更新
    await saveCurrentState();

    print('✅ 第 $level 层已加载完成');
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
    // 🧼 修正非法波次（最小值为 1）
    if (waveIndex < 1) {
      waveIndex = 1;
    }

    // 🧱 不存在或该波为空？
    final waveEmpty = !waves.containsKey(waveIndex) || waves[waveIndex]!.isEmpty;

    if (waveEmpty) {
      print('⏭️ 当前波 $waveIndex 不存在或为空');

      if (waveIndex >= totalWaves) {
        print('🏁 所有波次已完成，触发通关');
        _onHellCleared(); // ✅ 提前触发五角星发光逻辑
        return;
      }

      print('👉 继续尝试加载下一波 ${waveIndex + 1}');
      _loadWave(waveIndex + 1);
      return;
    }

    // ✅ 真正加载该波次
    currentWave = waveIndex;
    print('📣 正在加载波次 $currentWave，怪物数: ${waves[currentWave]!.length}');

    for (final monster in waves[currentWave]!) {
      mapRoot.add(monster);
    }

    _waveFinished = false;

    // ✅ 延迟检查是否“加载即通关”
    Future.delayed(const Duration(milliseconds: 100), () {
      checkWaveProgress();
    });
  }

  Vector2 _getValidSpawnPosition(Random rng) {
    while (true) {
      final pos = Vector2(
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
        rng.nextInt(mapSize) * tileSize + tileSize / 2,
      );
      if ((pos - safeZoneCenter).length > safeZoneRadius + tileSize * 3) {
        return pos;
      }
    }
  }

  Vector2 _getBossSpawnPosition(Random rng) {
    final edgeX = rng.nextBool()
        ? rng.nextInt(mapSize ~/ 4) * tileSize + tileSize / 2
        : (mapSize - rng.nextInt(mapSize ~/ 4)) * tileSize + tileSize / 2;
    final edgeY = rng.nextBool()
        ? rng.nextInt(mapSize ~/ 4) * tileSize + tileSize / 2
        : (mapSize - rng.nextInt(mapSize ~/ 4)) * tileSize + tileSize / 2;
    return Vector2(edgeX.toDouble(), edgeY.toDouble());
  }

  Future<void> _restoreWavesFromSave(List<dynamic> savedList) async {
    waves.clear();
    final grouped = <int, List<HellMonsterComponent>>{};

    print('📦 开始恢复怪物列表，总数: ${savedList.length}');

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

    print('✅ 怪物恢复完成，共 ${waves.length} 个波次');
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
        .where((m) => m.hp > 0) // ✅ 只保存还活着的怪物
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
    }).toList();

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

    if (raw == null) {
      print('📂 没有找到存档数据（首次进入或未保存）');
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      print('📥 成功读取存档：');
      print('🔹 Level: ${decoded['level']}');
      print('🔹 当前波次: ${decoded['currentWave']}');
      print('🔹 玩家位置: ${decoded['player']['x']}, ${decoded['player']['y']}');
      print('🔹 玩家HP: ${decoded['player']['hp']}');
      print('🔹 怪物数量: ${(decoded['monsters'] as List).length}');

      final grouped = <int, int>{};
      for (final m in decoded['monsters']) {
        final idx = m['waveIndex'];
        grouped[idx] = (grouped[idx] ?? 0) + 1;
      }
      for (final entry in grouped.entries) {
        print('⚔️ 波次 ${entry.key} -> 怪物数量: ${entry.value}');
      }

      return decoded;
    } catch (e) {
      print('❌ 存档解析失败: $e');
      return null;
    }
  }

  @override
  Color backgroundColor() => Colors.black;
}
