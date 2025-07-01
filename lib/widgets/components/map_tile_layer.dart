import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/noise_utils.dart';

class MapTileLayer extends PositionComponent {
  final int rows;
  final int cols;
  final double tileSize;
  final double decorationTileSize;
  final int currentFloor;

  final int minCount;
  final int maxCount;
  final double minSize;
  final double maxSize;

  final List<String> tileSpritePaths = [
    'huanyue/tietu_caocong.png',
    'huanyue/tietu_dashu.png',
    'huanyue/tietu_gouhuo.png',
    'huanyue/tietu_mogu.png',
  ];

  late final NoiseUtils noise;
  double frequency = 0.005;
  int octaves = 5;
  double persistence = 0.7;

  final Map<String, ui.Image> cachedImages = {};

  /// 🌟 最终生成的缓存Image
  late ui.Image _terrainImage;

  bool _initialized = false;

  MapTileLayer({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.decorationTileSize,
    required this.currentFloor,
    this.minCount = 0,
    this.maxCount = 3,
    this.minSize = 8.0,
    this.maxSize = 48.0,
  }) : super() {
    noise = NoiseUtils(currentFloor + 8888);
    size = Vector2(cols * tileSize, rows * tileSize);
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    // 🌟 加载所有贴图
    for (final path in tileSpritePaths) {
      final img = await Flame.images.load(path);
      cachedImages[path] = img;
    }

    // 🌟 一次性生成Image
    _terrainImage = await _generateTerrainImage();

    _initialized = true;
  }

  /// 🌟 一次性生成Image
  Future<ui.Image> _generateTerrainImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final rand = Random(currentFloor);

    // 🚀 1. 先画噪声底色
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final h = noise.fbm(
          x.toDouble(),
          y.toDouble(),
          octaves,
          frequency,
          persistence,
        );
        final color = _terrainColor(h);

        final rect = ui.Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );
        canvas.drawRect(rect, ui.Paint()..color = color);
      }
    }

    // 🚀 2. 再画贴图
    final decoCols = (size.x / decorationTileSize).ceil();
    final decoRows = (size.y / decorationTileSize).ceil();

    for (int dy = 0; dy < decoRows; dy++) {
      for (int dx = 0; dx < decoCols; dx++) {
        final count = rand.nextInt(maxCount - minCount + 1) + minCount;

        for (int i = 0; i < count; i++) {
          if (rand.nextDouble() < 0.4) {
            final baseX = dx * decorationTileSize;
            final baseY = dy * decorationTileSize;

            // 🌊 判断tile中心是否为海洋
            final tileCenterX = (baseX + decorationTileSize / 2) / tileSize;
            final tileCenterY = (baseY + decorationTileSize / 2) / tileSize;
            final h = noise.fbm(
              tileCenterX,
              tileCenterY,
              octaves,
              frequency,
              persistence,
            );
            if (h < -0.19) continue;

            final spritePath = tileSpritePaths[rand.nextInt(tileSpritePaths.length)];
            final img = cachedImages[spritePath];
            if (img == null) continue;

            final decoSize = minSize + rand.nextDouble() * (maxSize - minSize);
            final offsetX = rand.nextDouble() * (decorationTileSize - decoSize);
            final offsetY = rand.nextDouble() * (decorationTileSize - decoSize);

            canvas.drawImageRect(
              img,
              ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
              ui.Rect.fromLTWH(baseX + offsetX, baseY + offsetY, decoSize, decoSize),
              ui.Paint(),
            );
          }
        }
      }
    }

    final picture = recorder.endRecording();

    // 🌟 把Picture转成Image
    return await picture.toImage(
      (cols * tileSize).toInt(),
      (rows * tileSize).toInt(),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    if (!_initialized) return;
    canvas.drawImage(_terrainImage, ui.Offset.zero, ui.Paint());
  }

  ui.Color _terrainColor(double h) {
    if (h < -0.19) return const ui.Color(0xFF3C75C6);
    if (h < 0.02) return const ui.Color(0xFF88C070);
    if (h < 0.14) return const ui.Color(0xFF568E33);
    if (h < 0.29) return const ui.Color(0xFFD7C18D);
    if (h < 0.44) return const ui.Color(0xFFB7B7B7);
    if (h < 0.66) return const ui.Color(0xFFE8E8E8);
    return const ui.Color(0xFFE27D60);
  }
}
