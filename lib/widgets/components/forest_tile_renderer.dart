import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class ForestTileRenderer {
  final List<Sprite> _sprites = [];
  final int seed;

  ForestTileRenderer({this.seed = 1337});

  /// 🌲 加载所有树木贴图（tree_1.png ~ tree_5.png）
  Future<void> loadAssets() async {
    for (int i = 1; i <= 5; i++) {
      final sprite = await Sprite.load('floating_island/tree_$i.png');
      _sprites.add(sprite);
    }
  }

  /// ✅ 在已有背景上叠加贴图（不覆盖原地形）
  void renderIfNeeded(Canvas canvas, double noiseVal, Vector2 worldPos, double scale) {
    const double treeGridSize = 32.0; // 每棵树占据的格子大小（单位像素）

    final gridX = (worldPos.x / treeGridSize).floor();
    final gridY = (worldPos.y / treeGridSize).floor();
    final hash = _hash(gridX, gridY, seed);

    final chance = (1.0 - (noiseVal - 0.6).abs() / 0.1).clamp(0, 1);
    final roll = (hash % 1000) / 1000.0;
    if (roll > chance) return;

    final spriteIndex = hash % _sprites.length;
    final sprite = _sprites[spriteIndex];

    // ❌ 不乘 scale，直接用真实像素单位渲染
    final size = Vector2.all(treeGridSize);

    final offset = Vector2(
      gridX * treeGridSize + treeGridSize / 2,
      gridY * treeGridSize + treeGridSize / 2,
    );

    sprite.render(
      canvas,
      position: offset,
      size: size,
      anchor: Anchor.center,
    );
  }

  /// 🧠 稳定 hash 函数（基于 tile 坐标和种子）
  int _hash(int x, int y, int seed) {
    int n = x * 73856093 ^ y * 19349663 ^ seed * 83492791;
    return n & 0x7fffffff;
  }
}
