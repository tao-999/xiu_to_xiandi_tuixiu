import 'dart:math';

class NoiseUtils {
  final int seed;
  late final List<int> perm;

  NoiseUtils(this.seed) {
    final rand = Random(seed);
    final base = List.generate(256, (i) => i)..shuffle(rand);
    perm = List.from(base)..addAll(base);
  }

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

  /// 🌱 Perlin噪声 (支持repeat)
  double perlin(double x, double y, [int? repeat]) {
    if (x.isNaN || y.isNaN || x.isInfinite || y.isInfinite) {
      throw Exception('💥 Invalid input to perlin: x=$x, y=$y');
    }

    if (repeat != null && repeat > 0) {
      x = x % repeat;
      y = y % repeat;
    }

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

  /// 🔁 fBM (支持repeat)
  double fbm(double x, double y, int octaves, double frequency, double persistence, [int? repeat]) {
    double total = 0.0;
    double amplitude = 1.0;
    double maxAmplitude = 0.0;

    for (int i = 0; i < octaves; i++) {
      double f = frequency * pow(2.0, i);
      total += perlin(x * f, y * f, repeat) * amplitude;
      maxAmplitude += amplitude;
      amplitude *= persistence;
    }
    return total / maxAmplitude;
  }
}
