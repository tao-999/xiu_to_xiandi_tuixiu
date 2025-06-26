import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// ✅ 通用贴图覆盖渲染器，可用于森林、石头、灌木等 tile 区域叠加贴图
class TileOverlayRenderer {
  final String tileType;     // 贴图类型，比如 'tree'、'rock'、'bush'
  final int tileSize;        // 每个 tile 所占像素尺寸，默认 32
  final int spriteCount;     // 每种贴图对应的图数量，如 tree_1~tree_5
  final int seed;            // 随机种子，控制 hash 贴图分布

  final List<Sprite> _sprites = [];

  TileOverlayRenderer({
    required this.tileType,
    this.tileSize = 32,
    this.spriteCount = 5,
    this.seed = 1337,
  });

  /// 📦 自动加载贴图，使用 Sprite.load 不依赖 images 实例
  Future<void> loadAssets() async {
    for (int i = 1; i <= spriteCount; i++) {
      final sprite = await Sprite.load('floating_island/${tileType}_$i.png');
      _sprites.add(sprite);
    }
  }

  /// ✅ 渲染贴图（需要传入判断函数判断是否满足贴图条件）
  void renderIfNeeded(
      Canvas canvas,
      double noiseVal,
      Vector2 worldPos,
      double scale,
      bool Function(Vector2 pos) conditionCheck,
      ) {
    final gridX = (worldPos.x / tileSize).floor();
    final gridY = (worldPos.y / tileSize).floor();
    final hash = _hash(gridX, gridY, seed);

    final chance = (1.0 - (noiseVal - 0.6).abs() / 0.1).clamp(0, 1);
    final roll = (hash % 1000) / 1000.0;
    if (roll > chance) return;

    final drawPos = Vector2(
      gridX * tileSize + tileSize / 2,
      gridY * tileSize + tileSize / 2,
    );

    // ✅ 区域检测：整块 tileSize 区域必须全部符合条件
    final regionStart = Vector2(gridX * tileSize.toDouble(), gridY * tileSize.toDouble());

    const int steps = 4;
    final double stepSize = tileSize / steps;

    for (int dx = 0; dx < steps; dx++) {
      for (int dy = 0; dy < steps; dy++) {
        final checkPos = regionStart + Vector2(dx * stepSize, dy * stepSize);
        if (!conditionCheck(checkPos)) return; // ❌ 一旦不满足条件，终止渲染
      }
    }

    // ✅ 渲染贴图
    final spriteIndex = hash % _sprites.length;
    final sprite = _sprites[spriteIndex];
    final size = Vector2.all(tileSize.toDouble());

    sprite.render(
      canvas,
      position: drawPos,
      size: size,
      anchor: Anchor.center,
      overridePaint: Paint()..filterQuality = FilterQuality.none, // 防止贴图缝隙
    );
  }

  /// 🧠 稳定 hash，控制贴图分布
  int _hash(int x, int y, int seed) {
    int n = x * 73856093 ^ y * 19349663 ^ seed * 83492791;
    return n & 0x7fffffff;
  }
}
