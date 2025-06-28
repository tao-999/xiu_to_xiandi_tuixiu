import 'dart:convert';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/chiyangu_storage.dart';
import 'dirt_cell_component.dart';
import 'rock_cell_component.dart';
import 'mining_cell_component.dart';

class ChiyanguGame extends FlameGame {
  static const int cols = 6;

  late double cellSize;

  final Map<String, PositionComponent> cellMap = {};
  final PositionComponent maskLayer = PositionComponent();
  final PositionComponent mapLayer = PositionComponent();

  int currentDepth = 0;
  int visibleRows = 0;

  bool isShifting = false;
  String? lastTappedKey;
  DateTime? lastTapTime;

  static final ValueNotifier<int> depthNotifier = ValueNotifier<int>(0);

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final screenWidth = size.x;
    final screenHeight = size.y;

    // ✅ 动态计算 cellSize，最大不超过 64
    cellSize = min(screenWidth / cols, 64);
    mapLayer.position = Vector2((size.x - cols * cellSize) / 2, 0);

    visibleRows = (screenHeight / cellSize).ceil();

    maskLayer.size = Vector2(cols * cellSize, visibleRows * cellSize);
    maskLayer.position = Vector2.zero();
    add(maskLayer);
    maskLayer.add(mapLayer);

    // ✅ 加载地图
    final saved = await ChiyanguStorage.load();
    if (saved != null) {
      final savedCells = saved['cells'] as Map<String, Map<String, dynamic>>;
      currentDepth = saved['depth'] ?? visibleRows;
      await _buildCellMapFromSavedData(savedCells);
      mapLayer.position.y = await _loadOffsetY();
    } else {
      currentDepth = visibleRows;
      for (int row = 0; row < visibleRows; row++) {
        _addRow(row);
      }
    }

    depthNotifier.value = _getTopVisibleRow();
  }

  Future<double> _loadOffsetY() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('chiyangu_map_offset_y') ?? 0.0;
  }

  Future<void> saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final offsetY = mapLayer.position.y;

    await prefs.setDouble('chiyangu_map_offset_y', offsetY);

    await ChiyanguStorage.save(
      depth: currentDepth,
      cells: buildCellStorageData(),
    );
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
        .reduce(min);

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
    if (isShifting) return;
    isShifting = true;
    final double distance = -cellSize * lines;

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
          depthNotifier.value = _getTopVisibleRow();
          isShifting = false;
        },
      ),
    );
  }

  void tryShiftIfNeeded(String fromKey, {bool onlyIfTapped = false}) {
    if (isShifting) return;
    if (onlyIfTapped && !isTappedCell(fromKey)) return;

    final self = cellMap[fromKey];
    if (self is! PositionComponent) return;

    final selfY = self.position.y;
    final topY = cellMap.values.map((c) => c.position.y).reduce(min);
    final secondY = topY + cellSize;

    int shiftLines = 0;

    if ((selfY - topY).abs() < 0.01) {
      if (self is DirtCellComponent) {
        final below = _getComponentAt(self.position.x, self.position.y + cellSize);
        if (below is DirtCellComponent) shiftLines = 1;
      }
    } else if ((selfY - secondY).abs() < 0.01) {
      final below = _getComponentAt(self.position.x, self.position.y + cellSize);
      if (self is DirtCellComponent && below is DirtCellComponent) {
        shiftLines = 2;
      } else {
        shiftLines = 1;
      }
    }

    if (shiftLines > 0) {
      shiftGridUp(lines: shiftLines);
    }
  }

  void breakAdjacent(String gridKey, {bool fromDirt = true}) {
    final parts = gridKey.split('_');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    for (final offset in [
      [0, -1], [0, 1], [-1, 0], [1, 0],
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

  int _getTopVisibleRow() {
    final rows = cellMap.keys.map((key) => int.parse(key.split('_')[0]));
    return rows.isEmpty ? 0 : rows.reduce(min);
  }

  Map<String, Map<String, dynamic>> buildCellStorageData() {
    final result = <String, Map<String, dynamic>>{};
    cellMap.forEach((key, comp) {
      if (comp is DirtCellComponent) {
        result[key] = {
          'type': 'dirt',
          'breakLevel': comp.broken ? 1 : 0,
        };
      } else if (comp is RockCellComponent) {
        result[key] = {
          'type': 'rock',
          'breakLevel': comp.hitCount.clamp(0, 3),
        };
      }
    });
    return result;
  }

  Future<void> _buildCellMapFromSavedData(Map<String, Map<String, dynamic>> data) async {
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      final parts = key.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final x = col * cellSize;
      final y = row * cellSize;
      final position = Vector2(x, y);
      final type = value['type'];
      final breakLevel = value['breakLevel'] ?? 0;

      PositionComponent? cell;

      if (type == 'dirt') {
        if (breakLevel == 1) continue;
        final dirt = DirtCellComponent(
          position: position,
          size: cellSize,
          depth: row,
          gridKey: key,
        );
        cell = dirt;
        cellMap[key] = dirt;
        mapLayer.add(dirt);
      } else if (type == 'rock') {
        if (breakLevel >= 3) continue;
        final rock = RockCellComponent(
          position: position,
          size: cellSize,
          gridKey: key,
        );
        cell = rock;
        cellMap[key] = rock;
        mapLayer.add(rock);
        await rock.restoreFromStorage(breakLevel);
      }
    }

    currentDepth = cellMap.keys.map((k) => int.parse(k.split('_')[0]))
        .fold(0, (prev, curr) => curr >= prev ? curr + 1 : prev);
  }

  Future<Map<String, Map<String, dynamic>>> _loadSavedCellData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('chiyangu_cell_data');
    if (str == null) return {};
    final raw = jsonDecode(str) as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(
      key,
      Map<String, dynamic>.from(value),
    ));
  }
}
