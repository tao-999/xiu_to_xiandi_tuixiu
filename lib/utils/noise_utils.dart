import 'dart:math';

class NoiseUtils {
  final int seed;
  late final List<int> perm; // ✅ 加了 late

  NoiseUtils(this.seed) {
    final rand = Random(seed);
    final base = List.generate(256, (i) => i)..shuffle(rand);
    perm = List.from(base)..addAll(base); // ✅ 只赋值一次，合法
  }

  // 🧭 2D 梯度向量
  static final List<List<int>> gradients = [
    [1, 1], [-1, 1], [1, -1], [-1, -1],
    [1, 0], [-1, 0], [0, 1], [0, -1],
  ];

  double fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);
  double lerp(double a, double b, double t) => a + t * (b - a);

  double grad(int hash, double x, double y) {
    final g = gradients[hash % gradients.length];
    return g[0] * x + g[1] * y;
  }

  /// 🌀 经典 Perlin 噪声
  double perlin(double x, double y) {
    int X = x.floor() & 255;
    int Y = y.floor() & 255;

    double xf = x - x.floor();
    double yf = y - y.floor();

    int aa = perm[X + perm[Y]];
    int ab = perm[X + perm[Y + 1]];
    int ba = perm[X + 1 + perm[Y]];
    int bb = perm[X + 1 + perm[Y + 1]];

    double u = fade(xf);
    double v = fade(yf);

    double x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u);
    double x2 = lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u);

    return lerp(x1, x2, v);
  }

  /// 🔁 fBM 叠加：构造地形层次
  double fbm(double x, double y, int octaves, double frequency, double persistence) {
    double total = 0.0;
    double amplitude = 1.0;
    double maxAmplitude = 0.0;

    for (int i = 0; i < octaves; i++) {
      total += perlin(x * frequency, y * frequency) * amplitude;
      maxAmplitude += amplitude;
      amplitude *= persistence;
      frequency *= 2.0;
    }

    return total / maxAmplitude; // [-1, 1]
  }
}
