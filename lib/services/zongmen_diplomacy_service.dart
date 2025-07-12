import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class ZongmenDiplomacyService {
  static const String _boxName = 'zongmen_diplomacy';

  static Box? _box;

  /// 懒加载box
  static Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  /// 保存所有宗门位置 & 角色位置
  static Future<void> save({
    required List<MapEntry<int, Vector2>> sectPositions,
    required Vector2 playerPosition,
  }) async {
    final box = await _getBox();
    final sectData = sectPositions
        .map((e) => {
      'id': e.key,
      'x': e.value.x,
      'y': e.value.y,
    })
        .toList();

    final playerData = {
      'x': playerPosition.x,
      'y': playerPosition.y,
    };

    await box.put('sects', sectData);
    await box.put('player', playerData);
  }

  /// 加载所有宗门位置 & 角色位置
  static Future<Map<String, dynamic>> load() async {
    final box = await _getBox();
    final sectData = box.get('sects') as List<dynamic>? ?? [];
    final playerData = box.get('player') as Map<dynamic, dynamic>?;

    // 解析宗门
    final sectPositions = sectData.map((e) {
      final map = e as Map<dynamic, dynamic>;
      return MapEntry(
        map['id'] as int,
        Vector2((map['x'] as num).toDouble(), (map['y'] as num).toDouble()),
      );
    }).toList();

    // 解析角色
    Vector2 playerPosition;
    if (playerData == null) {
      playerPosition = Vector2(2560.0, 2560.0);
      debugPrint('[DiplomacyMap] 玩家位置为空，使用默认中心: $playerPosition');
    } else {
      playerPosition = Vector2(
        (playerData['x'] as num).toDouble(),
        (playerData['y'] as num).toDouble(),
      );
      debugPrint('[DiplomacyMap] 玩家位置加载: $playerPosition');
    }

    return {
      'sects': sectPositions,
      'player': playerPosition,
    };
  }

  /// 清空
  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
