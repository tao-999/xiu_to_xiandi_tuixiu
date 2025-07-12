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
    if (repeat != null) {
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

  /// 🌈 Simplex Noise (简易近似)
  double simplex(double x, double y) {
    return perlin(x, y);
  }

  /// 🟢 Value Noise
  double valueNoise(double x, double y) {
    int xi = x.floor();
    int yi = y.floor();
    double xf = x - xi;
    double yf = y - yi;

    int seedA = _hash(xi, yi);
    int seedB = _hash(xi + 1, yi);
    int seedC = _hash(xi, yi + 1);
    int seedD = _hash(xi + 1, yi + 1);

    double va = _pseudoRandom(seedA);
    double vb = _pseudoRandom(seedB);
    double vc = _pseudoRandom(seedC);
    double vd = _pseudoRandom(seedD);

    double u = fade(xf);
    double v = fade(yf);

    double x1 = lerp(va, vb, u);
    double x2 = lerp(vc, vd, u);
    return lerp(x1, x2, v) * 2 - 1; // [-1,1]
  }

  /// 🟡 Worley Noise (Cellular)
  double worley(double x, double y, {int gridSize = 16}) {
    int xi = x ~/ gridSize;
    int yi = y ~/ gridSize;

    double minDist = double.infinity;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int nx = xi + dx;
        int ny = yi + dy;
        final rnd = _randomPointInCell(nx, ny, gridSize);
        double px = nx * gridSize + rnd[0];
        double py = ny * gridSize + rnd[1];
        double dist = sqrt(pow(x - px, 2) + pow(y - py, 2));
        if (dist < minDist) minDist = dist;
      }
    }
    return (gridSize - minDist) / gridSize * 2 - 1; // [-1,1]
  }

  /// 🔵 White Noise
  double whiteNoise(double x, double y) {
    return _pseudoRandom(_hash(x.floor(), y.floor())) * 2 - 1;
  }

  /// 工具 - Hash
  int _hash(int x, int y) {
    return (x * 374761393 + y * 668265263) ^ seed;
  }

  /// 工具 - Pseudo Random
  double _pseudoRandom(int s) {
    return ((sin(s) * 43758.5453) % 1).abs();
  }

  /// 工具 - Random point in cell
  List<double> _randomPointInCell(int x, int y, int gridSize) {
    final s = _hash(x, y);
    final r1 = _pseudoRandom(s);
    final r2 = _pseudoRandom(s + 1);
    return [r1 * gridSize, r2 * gridSize];
  }
}
