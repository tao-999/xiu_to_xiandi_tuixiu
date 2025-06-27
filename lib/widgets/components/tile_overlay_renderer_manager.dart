import 'dart:ui';
import 'package:flame/components.dart';
import 'tile_overlay_renderer.dart';

class TileOverlayRendererManager {
  final Map<String, TileOverlayRenderer> _renderers = {};
  final int seed;

  TileOverlayRendererManager({this.seed = 1337});

  /// ✅ 注册地形类型及其对应贴图前缀
  void register({
    required String terrainType, // 地形名：如 forest、hill、ruin
    required String tileType,    // 贴图前缀名：如 tree、rock、statue
    int tileSize = 32,
    int spriteCount = 5,
  }) {
    _renderers[terrainType] = TileOverlayRenderer(
      tileType: tileType,
      tileSize: tileSize,
      spriteCount: spriteCount,
      seed: seed,
    );
  }

  /// 📦 统一加载所有贴图资源
  Future<void> loadAllAssets() async {
    for (final renderer in _renderers.values) {
      await renderer.loadAssets();
    }
  }

  /// ✅ 根据地形类型调用对应的 renderer 渲染贴图
  void renderIfNeeded({
    required Canvas canvas,
    required String terrainType,
    required double noiseVal,
    required Vector2 worldPos,
    required double scale,
    required Vector2 cameraOffset, // ✅ 新增
    required bool Function(Vector2) conditionCheck,
  }) {
    final renderer = _renderers[terrainType];
    if (renderer != null) {
      renderer.renderIfNeeded(
        canvas,
        noiseVal,
        worldPos,
        scale,
        cameraOffset, // ✅ 新增
        conditionCheck,
      );
    }
  }
}
