import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import '../../models/hell_game_state.dart';
import '../../services/hell_service.dart';
import '../../services/resources_storage.dart';
import '../components/hell_monster_component.dart';
import '../components/monster_wave_info.dart';

class HellMonsterManager {
  final int level;
  final int totalCount;
  final int initialSpawnCount;
  final PositionComponent mapRoot;
  final PositionComponent player;
  final Vector2 safeZoneCenter;
  final double safeZoneRadius;
  final MonsterWaveInfo monsterWaveInfo;

  HellMonsterComponent? bossMonster;
  bool bossSpawned = false;
  int killedCount = 0;
  int spawnedCount = 0;

  HellMonsterManager({
    required this.level,
    required this.totalCount,
    this.initialSpawnCount = 10,
    required this.mapRoot,
    required this.player,
    required this.safeZoneCenter,
    required this.safeZoneRadius,
    required this.monsterWaveInfo,
  });

  Future<void> initMonsters() async {
    final HellGameState? state = await HellService.loadState();
    final savedList = await HellService.loadAliveMonsters();
    final bossData = await HellService.loadBossMonster();

    debugPrint('🐲 [HellMonsterManager] 加载状态: ${state != null}');
    debugPrint('👾 已保存怪物数量: ${savedList.length}');
    debugPrint('👹 Boss是否存在: ${bossData != null}');

    if (state != null) {
      killedCount = state.killed;
      bossSpawned = state.bossSpawned;
      spawnedCount = state.spawned;
      monsterWaveInfo.updateInfo(killedCount);
      debugPrint('📦 [HellMonsterManager] 恢复击杀数: $killedCount, bossSpawned: $bossSpawned, spawned: $spawnedCount');

      for (final json in savedList) {
        final m = HellMonsterComponent(
          id: json['id'],
          isBoss: false,
          level: json['level'],
          hp: json['hp'],
          maxHp: json['maxHp'],
          atk: json['atk'],
          def: json['def'],
          position: Vector2(json['x'], json['y']),
          onDeathCallback: () => _onMonsterDead(isBoss: false),
        );
        m.trackTarget(player, speed: 30, safeCenter: safeZoneCenter, safeRadius: safeZoneRadius);
        mapRoot.add(m);
      }

      debugPrint('✅ [HellMonsterManager] 已恢复普通怪 ${savedList.length} 只');

      if (bossData != null) {
        bossMonster = HellMonsterComponent(
          id: bossData['id'],
          isBoss: true,
          level: bossData['level'],
          hp: bossData['hp'],
          maxHp: bossData['maxHp'],
          atk: bossData['atk'],
          def: bossData['def'],
          position: Vector2(bossData['x'], bossData['y']),
          onDeathCallback: () => _onMonsterDead(isBoss: true),
        )..trackTarget(player, speed: 20, safeCenter: safeZoneCenter, safeRadius: safeZoneRadius);
        mapRoot.add(bossMonster!);
        debugPrint('✅ [HellMonsterManager] 已恢复Boss怪');
      }

      debugPrint('📦 [HellMonsterManager] 状态恢复成功');
    } else {
      killedCount = 0;
      bossSpawned = false;
      spawnedCount = 0;
      monsterWaveInfo.updateInfo(0);
      await HellService.saveState(killed: 0, bossSpawned: false, spawned: 0);
      spawnInitialMonsters();
      debugPrint('🆕 [HellMonsterManager] 初始化新状态 + 初始怪物');
    }
  }

  void spawnInitialMonsters() {
    for (int i = 0; i < initialSpawnCount; i++) {
      _spawnMonster();
    }
  }

  void _spawnMonster() {
    if (spawnedCount >= totalCount) return;
    final random = Random();
    final pos = _randomSpawnPosition(random);
    final attr = HellService.calculateMonsterAttributes(level: level, isBoss: false);
    final monster = HellMonsterComponent(
      id: spawnedCount,
      isBoss: false,
      level: level,
      hp: attr['hp']!,
      maxHp: attr['hp']!,
      atk: attr['atk']!,
      def: attr['def']!,
      position: pos,
      onDeathCallback: () => _onMonsterDead(isBoss: false),
    );
    monster.trackTarget(player, speed: 30, safeCenter: safeZoneCenter, safeRadius: safeZoneRadius);
    mapRoot.add(monster);
    spawnedCount++;
    unawaited(HellService.saveState(
      killed: killedCount,
      bossSpawned: bossSpawned,
      spawned: spawnedCount,
    ));
  }

  void _spawnBoss() {
    final random = Random();
    final pos = _randomSpawnPosition(random);
    final attr = HellService.calculateMonsterAttributes(level: level, isBoss: true);
    bossMonster = HellMonsterComponent(
      id: 9999,
      isBoss: true,
      level: level,
      hp: attr['hp']!,
      maxHp: attr['hp']!,
      atk: attr['atk']!,
      def: attr['def']!,
      position: pos,
      onDeathCallback: () => _onMonsterDead(isBoss: true),
    );
    bossMonster!.trackTarget(player, speed: 20, safeCenter: safeZoneCenter, safeRadius: safeZoneRadius);
    mapRoot.add(bossMonster!);
    bossSpawned = true;
    unawaited(HellService.saveState(
      killed: killedCount,
      bossSpawned: bossSpawned,
      spawned: spawnedCount,
    ));
    debugPrint('👹 Boss已生成');
  }

  Future<void> _onMonsterDead({required bool isBoss}) async {
    killedCount++;

    final base = 10 + (level - 1) * 2;
    final reward = isBoss ? base * 2 : base;

    ResourcesStorage.add('spiritStoneMid', BigInt.from(reward));

    final prev = await HellService.loadSpiritStoneReward();
    final newTotal = prev + reward;
    await HellService.saveSpiritStoneReward(newTotal);

    monsterWaveInfo.updateInfo(killedCount, rewardOverride: newTotal);
    debugPrint('💀 击杀${isBoss ? 'Boss' : '怪物'} → 奖励：$reward，中品灵石累计：$newTotal');

    unawaited(HellService.saveStateAndLog(
      killed: killedCount,
      bossSpawned: bossSpawned,
      spawned: spawnedCount,
    ));

    unawaited(HellService.saveAliveMonsters(
      mapRoot.children.whereType<HellMonsterComponent>().where((m) => !m.isBoss).toList(),
    ));
    if (bossMonster != null && bossMonster!.isMounted) {
      unawaited(HellService.saveBossMonster(bossMonster!));
    }

    if (killedCount >= totalCount) {
      if (!bossSpawned) {
        debugPrint('🧠 判断路径 → 击杀数已满，未生成Boss → 生成Boss');
        _spawnBoss();
      } else {
        debugPrint('🧠 判断路径 → 击杀数已满，Boss已生成 → 无操作');
      }
    } else if (spawnedCount < totalCount) {
      debugPrint('🧠 判断路径 → 击杀数未满，已生成数量未达上限 → 刷新普通怪');
      _spawnMonster();
    } else {
      debugPrint('🧠 判断路径 → 击杀数未满，但已生成到上限 → 无操作');
    }
  }

  Vector2 _randomSpawnPosition(Random random) {
    Vector2 pos;
    int attempts = 0;
    do {
      pos = Vector2(
        random.nextDouble() * mapRoot.size.x,
        random.nextDouble() * mapRoot.size.y,
      );
      attempts++;
    } while ((pos - safeZoneCenter).length < safeZoneRadius + 100 && attempts < 10);
    return pos;
  }

  Future<void> reset() async {
    mapRoot.children.whereType<HellMonsterComponent>().forEach((m) => m.removeFromParent());
    bossMonster = null;
    bossSpawned = false;
    killedCount = 0;
    spawnedCount = 0;
    await HellService.clearAll();
    monsterWaveInfo.updateInfo(0);
    debugPrint('🧹 怪物管理器已重置');
  }

  int get monstersAlive => mapRoot.children.whereType<HellMonsterComponent>().length;

  bool get isBossSpawned => bossSpawned;
}
