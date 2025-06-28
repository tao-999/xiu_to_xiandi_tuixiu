import 'dart:ui';
import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/utils/noise_utils.dart';

class MapTileLayer extends PositionComponent {
  final int rows;
  final int cols;
  final double tileSize;
  final int currentFloor;

  late final NoiseUtils noise;
  double frequency = 0.05;   // 可根据地图风格微调
  int octaves = 2;
  double persistence = 0.4;

  MapTileLayer({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.currentFloor,
  }) : super() {
    // 直接在构造函数里初始化，避免 LateInitializationError
    noise = NoiseUtils(currentFloor + 8888);
    size = Vector2(cols * tileSize, rows * tileSize);
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    // 1. 绘制渐变色 tile 格子
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final h = noise.fbm(x.toDouble(), y.toDouble(), octaves, frequency, persistence);
        final color = _terrainColor(h);
        final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
        canvas.drawRect(rect, Paint()..color = color);
      }
    }
    // 2. 调用父类 render，继续渲染墙体/障碍/装饰等其他组件
    super.render(canvas);
  }

  // 地形噪声高度区间 -> 颜色映射，想怎么骚就怎么骚！
  Color _terrainColor(double h) {
    if (h < -0.19) return const Color(0xFF3C75C6);      // 湖泊蓝
    if (h < 0.02)  return const Color(0xFF88C070);      // 草原绿
    if (h < 0.14)  return const Color(0xFF568E33);      // 森林深绿
    if (h < 0.29)  return const Color(0xFFD7C18D);      // 沙地黄
    if (h < 0.44)  return const Color(0xFFB7B7B7);      // 石地灰
    if (h < 0.66)  return const Color(0xFFE8E8E8);      // 雪原白
    return const Color(0xFFE27D60);                     // 火山岩
  }
}
