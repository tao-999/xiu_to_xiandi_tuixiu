import 'package:flame/components.dart';
import 'noise_tile_map_generator.dart';

class InfiniteGridPainterComponent extends PositionComponent {
  final double tileSize;
  final int seed;
  final double frequency;

  double viewScale = 1.0;
  Vector2 viewSize = Vector2.zero();

  late final NoiseTileMapGenerator _generator;

  InfiniteGridPainterComponent({
    this.tileSize = 16.0,
    this.seed = 520,
    this.frequency = 0.0004,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _generator = NoiseTileMapGenerator(
      tileSize: tileSize,
      seed: seed,
      frequency: frequency,
    )
      ..viewScale = viewScale
      ..viewSize = viewSize;

    add(_generator);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 实时同步视图参数
    _generator
      ..viewScale = viewScale
      ..viewSize = viewSize;
  }
}
