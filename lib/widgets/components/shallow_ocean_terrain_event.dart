import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../services/terrain_event_storage_service.dart';
import '../../data/xianren_female_data.dart';
import '../dialogs/xianren_dialog.dart';
import '../../models/disciple.dart';
import '../../services/disciple_storage.dart';
import '../../services/zongmen_storage.dart';
import '../../widgets/common/toast_tip.dart';

class ShallowOceanTerrainEvent {
  static final Random _rand = Random();

  static const int maxLevel = 30;
  static const int start = 100000000; // 起点
  static const int interval = 100000000; // 区间宽度

  static int getLevelByDistance(double distance) {
    if (distance < start) return 0;
    final level = ((distance - start) / interval).floor() + 1;
    return level.clamp(1, maxLevel);
  }

  static Future<bool> trigger(Vector2 pos, FlameGame game) async {
    final distance = pos.length;

    if (distance < start) {
      debugPrint('[ShallowOcean] 距离 <$start, 不触发');
      return false;
    }

    final level = getLevelByDistance(distance);
    debugPrint('[ShallowOcean] 当前Level: $level, 距离: $distance');

    // 查询是否已加入宗门
    final triggeredEvents = await TerrainEventStorageService.getTriggeredEvents(
      'shallow_ocean',
      Vector2.zero(),
    );

    final hasCompleted = triggeredEvents.any(
          (e) =>
      e['eventType'] == 'XIANREN_$level' &&
          e['status'] == 'completed',
    );

    debugPrint('[ShallowOcean] 是否已加入宗门: $hasCompleted');

    if (hasCompleted) {
      debugPrint('[ShallowOcean] 已加入宗门，不再触发');
      return false;
    }

    final chanceRoll = _rand.nextDouble();
    final isTriggered = chanceRoll < 0.005;

    debugPrint('[ShallowOcean] Roll值: $chanceRoll, 是否触发: $isTriggered');

    if (!isTriggered) {
      debugPrint('[ShallowOcean] 本次未触发，保留下次机会');
      return false;
    }

    final data = xianrenFemaleData[level - 1];

    debugPrint('[ShallowOcean] 成功触发仙人：${data['name']}');

    // 🌟10条骚气文案
    final List<String> joinMessages = [
      '「{name}」已加入宗门，共修仙道。',
      '🌿恭喜，仙人「{name}」加入座下！',
      '🌸「{name}」踏入宗门，缘起今朝。',
      '🌙「{name}」携灵韵归来，拜入门下。',
      '🦢仙人「{name}」已入宗，共参大道。',
      '⚡️「{name}」应道缘而来，愿随宗主同修。',
      '🍃「{name}」静立于堂前，誓守宗门。',
      '✨仙人「{name}」执弟子礼，拜入宗门。',
      '🌺「{name}」愿与宗门共证长生。',
      '💫「{name}」已随风而来，愿修无上大道。',
    ];

    showDialog(
      context: game.buildContext!,
      barrierDismissible: false,
      builder: (_) => XianrenDialog(
        name: data['name'] as String,
        description: data['description'] as String,
        imagePath: data['thumbnailPath'] as String,
        aptitude: data['aptitude'] as int,
        onJoinSect: () async {
            final zongmen = await ZongmenStorage.loadZongmen();
            if (zongmen == null) {
              ToastTip.show(
                game.buildContext!,
                '你还没有宗门，无法收下仙人！',
              );
              // 🚨不要关闭弹窗
              return;
            }

            // 🌟写入事件标记
            await TerrainEventStorageService.markTriggered(
              'shallow_ocean',
              Vector2.zero(),
              'XIANREN_$level',
              data: {
                'level': level,
                'distance': distance,
                'name': data['name'],
              },
              status: 'completed',
            );

            debugPrint('[ShallowOcean] 已写入加入宗门标记');

            // 🌟直接构造Disciple
            final disciple = Disciple(
              id: '',
              name: data['name'] as String,
              gender: data['gender'] as String,
              age: data['age'] as int,
              aptitude: data['aptitude'] as int,
              hp: data['hp'] as int,
              atk: data['atk'] as int,
              def: data['def'] as int,
              loyalty: 100,
              specialty: '',
              talents: [],
              lifespan: 1000,
              cultivation: 0,
              breakthroughChance: 0,
              skills: [],
              fatigue: 0,
              isOnMission: false,
              imagePath: data['imagePath'] as String,
              description: data['description'] as String,
              favorability: 0,
              role: '弟子',
              realmLevel: 0,
              // 🌟 ✨ 加上这三项百分比字段（从 aptitude 推导）
              extraHp: data['aptitude'] * 0.01,
              extraAtk: data['aptitude'] * 0.01,
              extraDef: data['aptitude'] * 0.01,
            );

            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final updated = disciple.copyWith(joinedAt: now);

            await DiscipleStorage.saveOrAdd(updated);

            debugPrint('[ShallowOcean] 加入宗门逻辑完成');

            // 🌟关闭弹窗（这里必须手动关闭）
            Navigator.of(game.buildContext!).pop();

            // 🌟随机提示
            final msgTemplate = joinMessages[_rand.nextInt(joinMessages.length)];
            final message = msgTemplate.replaceAll('{name}', data['name'] as String);

            ToastTip.show(
              game.buildContext!,
              message,
            );
          },
      ),
    );

    return true;
  }
}
