import 'dart:math';
import 'package:flame/components.dart';

import 'dirt_cell_component.dart';
import 'rock_cell_component.dart';

class MiningCellComponent {
  /// 工厂方法：随机生成一个格子（泥土或岩石）
  static PositionComponent random({
    required Vector2 position,
    required double size,
    required int depth,
    required String gridKey, // ✅ 新增：坐标key
  }) {
    final r = Random().nextDouble();
    if (r < 0.9) {
      return DirtCellComponent(
        position: position,
        size: size,
        depth: depth,
        gridKey: gridKey, // ✅ 传进去
      );
    } else {
      return RockCellComponent(
        position: position,
        size: size,
        gridKey: gridKey,
      );
    }
  }

  /// 创建指定类型格子
  static PositionComponent ofType({
    required String type,
    required Vector2 position,
    required double size,
    required int depth,
    required String gridKey, // ✅ 新增
  }) {
    switch (type) {
      case 'dirt':
        return DirtCellComponent(
          position: position,
          size: size,
          depth: depth,
          gridKey: gridKey, // ✅ 传进去
        );
      case 'rock':
        return RockCellComponent(
          position: position,
          size: size,
          gridKey: gridKey,
        );
      default:
        throw Exception('未知格子类型：$type');
    }
  }
}
