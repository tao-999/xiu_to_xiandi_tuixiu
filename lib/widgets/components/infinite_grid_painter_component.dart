import 'package:flame/components.dart';
import 'noise_tile_map_generator.dart';

/// 无限地图主画布（只负责承载 generator）
class InfiniteGridPainterComponent extends PositionComponent {
  /// 地形生成器实例，外部唯一传入
  final NoiseTileMapGenerator generator;

  /// 视口缩放
  double viewScale = 1.0;

  /// 视口尺寸
  Vector2 viewSize = Vector2.zero();

  InfiniteGridPainterComponent({
    required this.generator,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(generator); // 子组件形式，自动随 InfiniteGridPainterComponent 渲染
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 保证地形生成器拿到最新的视口参数
    generator
      ..viewScale = viewScale
      ..viewSize = viewSize;
  }
}
