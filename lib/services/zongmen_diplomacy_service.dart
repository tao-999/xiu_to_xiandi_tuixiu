import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../widgets/components/sect_info.dart';

class ZongmenDiplomacyService {
  static const String _boxName = 'zongmen_diplomacy';
  static Box? _box;

  static Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  /// 保存宗门位置 + 玩家位置
  static Future<void> save({
    required List<Map<String, dynamic>> sectData,
    required Vector2 playerPosition,
  }) async {
    final box = await _getBox();
    await box.put('sects', sectData);
    await box.put('player', {
      'x': playerPosition.x,
      'y': playerPosition.y,
    });
    debugPrint('[DiplomacyMap] 宗门数据已保存：${sectData.length}条');
  }

  /// 加载
  static Future<Map<String, dynamic>> load() async {
    final box = await _getBox();
    final sectData = box.get('sects') as List<dynamic>? ?? [];
    final playerData = box.get('player') as Map<dynamic, dynamic>?;

    // 🌟只返回最小必要字段
    final sects = sectData.map((e) {
      final map = e as Map<dynamic, dynamic>;

      return {
        'id': map['id'] as int,
        'level': map['level'] as int,
        'masterPowerAtLevel1': map['masterPowerAtLevel1'] as int? ?? 1000,
        'x': (map['x'] as num?)?.toDouble() ?? 0,
        'y': (map['y'] as num?)?.toDouble() ?? 0,
      };
    }).toList();

    Vector2 playerPosition;
    if (playerData == null) {
      playerPosition = Vector2(2560.0, 2560.0);
    } else {
      playerPosition = Vector2(
        (playerData['x'] as num).toDouble(),
        (playerData['y'] as num).toDouble(),
      );
    }

    return {
      'sects': sects,
      'player': playerPosition,
    };
  }

  /// 清空
  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }

  /// 🌟 保存一个宗门的讨伐状态（只允许一个弟子）
  static Future<void> setSectExpedition({
    required int sectId,
    required String discipleId,
  }) async {
    final box = await _getBox();
    Map<dynamic, dynamic> map = box.get('expeditions') as Map<dynamic, dynamic>? ?? {};

    map[sectId.toString()] = {
      'time': DateTime.now().millisecondsSinceEpoch,
      'discipleId': discipleId,
    };

    await box.put('expeditions', map);
    debugPrint('[Diplomacy] 已设置宗门$sectId的讨伐：$discipleId');
  }

  /// 🌟 获取所有讨伐记录
  static Future<Map<int, Map<String, dynamic>>> getAllExpeditions() async {
    final box = await _getBox();
    final rawMap = box.get('expeditions') as Map<dynamic, dynamic>? ?? {};

    return rawMap.map((k, v) {
      final intKey = int.tryParse(k.toString()) ?? -1;
      final valueMap = Map<String, dynamic>.from(v as Map);
      return MapEntry(intKey, valueMap);
    });
  }

  /// 🌟 清除某个宗门的讨伐
  static Future<void> clearSectExpedition(int sectId) async {
    final box = await _getBox();
    Map<dynamic, dynamic> map = box.get('expeditions') as Map<dynamic, dynamic>? ?? {};
    map.remove(sectId.toString());
    await box.put('expeditions', map);
    debugPrint('[Diplomacy] 已清除宗门$sectId的讨伐');
  }

  /// 🌟 更新宗门等级
  static Future<void> updateSectLevel({
    required int sectId,
    required int newLevel,
  }) async {
    final box = await _getBox();
    final sectData = box.get('sects') as List<dynamic>? ?? [];

    for (int i = 0; i < sectData.length; i++) {
      final map = sectData[i] as Map<dynamic, dynamic>;
      if (map['id'] == sectId) {
        final masterPowerAtLevel1 = map['masterPowerAtLevel1'] as int?;

        if (masterPowerAtLevel1 == null) {
          debugPrint('[Diplomacy] ❌ 宗门$sectId缺少masterPowerAtLevel1，无法升级');
          return;
        }

        // 🌟用withLevel生成新的属性
        final updated = SectInfo.withLevel(
          id: sectId,
          level: newLevel,
          masterPowerAtLevel1: masterPowerAtLevel1,
        );

        // 🌟更新map
        map['level'] = updated.level;
        map['masterPower'] = updated.masterPower;
        map['discipleCount'] = updated.discipleCount;
        map['disciplePower'] = updated.disciplePower;
        map['spiritStoneLow'] = updated.spiritStoneLow.toString();

        sectData[i] = map;

        await box.put('sects', sectData);
        debugPrint('[Diplomacy] 已更新宗门$sectId的等级：$newLevel (战力=${updated.masterPower})');
        return;
      }
    }

    debugPrint('[Diplomacy] 没找到宗门$sectId，无法更新等级');
  }

}
