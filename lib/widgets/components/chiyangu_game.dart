// 📦 文件：chiyangu_game.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';

import 'dirt_cell_component.dart';
import 'rock_cell_component.dart';
import 'mining_cell_component.dart';

class ChiyanguGame extends FlameGame {
  static const int cols = 6;
  static const double cellSize = 64;

  final Map<String, PositionComponent> cellMap = {};
  final PositionComponent maskLayer = PositionComponent();
  final PositionComponent mapLayer = PositionComponent();

  double startX = 0;
  double startY = 0;
  int currentDepth = 0;
  int visibleRows = 0;

  bool isShifting = false;
  String? lastTappedKey;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final screenWidth = size.x;
    final screenHeight = size.y;
    visibleRows = (screenHeight / cellSize).ceil();

    startX = (screenWidth - cols * cellSize) / 2;
    startY = 0;

    maskLayer.size = Vector2(cols * cellSize, visibleRows * cellSize);
    maskLayer.position = Vector2.zero();
    add(maskLayer);
    maskLayer.add(mapLayer);

    currentDepth = visibleRows;
    for (int row = 0; row < visibleRows; row++) {
      _addRow(row);
    }
  }

  void _addRow(int row) {
    for (int col = 0; col < cols; col++) {
      final x = col * cellSize;
      final y = row * cellSize;
      final key = '${row}_$col';

      final cell = MiningCellComponent.random(
        position: Vector2(x, y),
        size: cellSize,
        depth: row,
        gridKey: key,
      );

      cellMap[key] = cell;
      mapLayer.add(cell);
    }
  }

  void _removeTopRowAccurate() {
    final topY = cellMap.values
        .whereType<PositionComponent>()
        .map((c) => c.position.y)
        .reduce((a, b) => a < b ? a : b);

    final toRemove = <String>[];

    cellMap.forEach((key, comp) {
      if ((comp.position.y - topY).abs() < 0.01) {
        toRemove.add(key);
        comp.removeFromParent();
      }
    });

    for (final key in toRemove) {
      cellMap.remove(key);
    }
  }

  void shiftGridUp({int lines = 1}) {
    if (isShifting) {
      print('🚫 忽略重复 shift');
      return;
    }

    isShifting = true;
    final double distance = -cellSize * lines;

    print('🌍 shiftGridUp 被调用！lines: $lines');

    mapLayer.add(
      MoveEffect.by(
        Vector2(0, distance),
        EffectController(duration: 0.3, curve: Curves.easeIn),
        onComplete: () {
          for (int i = 0; i < lines; i++) {
            _removeTopRowAccurate();
            _addRow(currentDepth);
            currentDepth += 1;
          }
          isShifting = false;
        },
      ),
    );
  }

  void tryShiftIfNeeded(String fromKey, {bool onlyIfTapped = false}) {
    if (isShifting) {
      print('🚫 正在移动中，跳过这次 shift 判断 [$fromKey]');
      return;
    }

    if (onlyIfTapped && !isTappedCell(fromKey)) {
      print('🚫 [$fromKey] 不是主动点击，不触发 shift 判断');
      return;
    }

    final self = cellMap[fromKey];
    if (self is! PositionComponent) return;

    print('🧩 判断是否上移：key=$fromKey');
    final double selfY = self.position.y;

    final topY = cellMap.values
        .map((c) => c.position.y)
        .reduce((a, b) => a < b ? a : b);

    final secondY = topY + cellSize;
    print('🔹 selfY=$selfY, topY=$topY, secondY=$secondY');
    print('🔹 self类型: ${self.runtimeType}');

    // ✅ 打印格子所在层级
    if ((selfY - topY).abs() < 0.01) {
      print('🧱 当前是【最顶层】格子');
    } else if ((selfY - secondY).abs() < 0.01) {
      print('🧱 当前是【次顶层】格子');
    } else {
      print('🧱 当前不是顶层也不是次顶层');
    }

    int shiftLines = 0;

    // ✅ 最顶层：必须当前是 Dirt，且下方是 Dirt，才允许移动
    if ((selfY - topY).abs() < 0.01) {
      if (self is DirtCellComponent) {
        final below = _getComponentAt(self.position.x, self.position.y + cellSize);
        if (below is DirtCellComponent) {
          shiftLines = 1;
        }
      }
    }

    // ✅ 次顶层：Rock 也可以触发移动，但只有 Dirt+下方也是 Dirt 时才 2 行
    else if ((selfY - secondY).abs() < 0.01) {
      final below = _getComponentAt(self.position.x, self.position.y + cellSize);
      if (self is DirtCellComponent && below is DirtCellComponent) {
        shiftLines = 2;
      } else {
        shiftLines = 1;
      }
    }

    if (shiftLines > 0) {
      print('🚀 触发上移：移动 $shiftLines 行');
      shiftGridUp(lines: shiftLines);
    } else {
      print('🛑 [$fromKey] 不满足上移条件');
    }
  }

  void breakAdjacent(String gridKey, {bool fromDirt = true}) {
    final parts = gridKey.split('_');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    for (final offset in [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
    ]) {
      final r = row + offset[0];
      final c = col + offset[1];
      final key = '${r}_$c';

      final comp = cellMap[key];
      if (comp is DirtCellComponent && !comp.broken) {
        comp.externalBreak();
      }
    }
  }

  bool canBreak(String key) {
    final parts = key.split('_');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    if (row == 0) return true;

    final aboveKey = '${row - 1}_$col';
    final above = cellMap[aboveKey];

    if (above == null) return true;
    if (above is DirtCellComponent) return above.broken;
    if (above is RockCellComponent) return above.isBroken;
    return false;
  }

  bool isTappedCell(String key) => lastTappedKey == key;

  PositionComponent? _getComponentAt(double x, double y) {
    for (final comp in cellMap.values) {
      if ((comp.position.x - x).abs() < 0.01 &&
          (comp.position.y - y).abs() < 0.01) {
        return comp;
      }
    }
    return null;
  }
}
