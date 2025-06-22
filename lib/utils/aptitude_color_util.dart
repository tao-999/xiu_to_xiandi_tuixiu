// 📦 lib/utils/aptitude_color_util.dart

import 'package:flutter/material.dart';

class AptitudeColorUtil {
  static BoxDecoration getBackgroundDecoration(int aptitude) {
    final decorations = <int, BoxDecoration>{
      10: BoxDecoration(color: Colors.grey.shade300),
      20: BoxDecoration(color: Colors.grey.shade300),
      30: BoxDecoration(color: Colors.grey.shade300),
      40: BoxDecoration(color: Colors.green.shade100),
      50: BoxDecoration(color: Colors.blue.shade100),
      60: BoxDecoration(color: Colors.purple.shade100),
      70: BoxDecoration(color: Colors.amber.shade100),
      80: BoxDecoration(color: Colors.red.shade200),
      90: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.white])),
      100: BoxDecoration(gradient: LinearGradient(colors: [Colors.cyan.shade100, Colors.white, Colors.indigo.shade100])),

      // ✅ 110 ~ 140：4色
      110: _gradient([Colors.teal.shade100, Colors.pink.shade50, Colors.yellow.shade100, Colors.indigo.shade50]),
      120: _gradient([Colors.orange.shade100, Colors.white, Colors.blue.shade100, Colors.green.shade100]),
      130: _gradient([Colors.deepPurple.shade100, Colors.cyan.shade100, Colors.pink.shade100, Colors.white]),
      140: _gradient([Colors.red.shade100, Colors.amber.shade100, Colors.purple.shade100, Colors.white]),

      // ✅ 150~160：5色
      150: _gradient([Colors.deepOrangeAccent, Colors.white, Colors.cyanAccent, Colors.indigoAccent, Colors.amberAccent]),
      160: _gradient([Colors.lightGreenAccent, Colors.tealAccent, Colors.white, Colors.indigo, Colors.purpleAccent]),

      // ✅ 170~180：6色
      170: _gradient([Colors.black87, Colors.pinkAccent, Colors.cyanAccent, Colors.white70, Colors.deepPurple, Colors.amber]),
      180: _gradient([Colors.lightBlueAccent, Colors.greenAccent, Colors.white, Colors.deepOrangeAccent, Colors.purple, Colors.yellowAccent]),

      // ✅ 190：6色
      190: _gradient([Colors.pinkAccent, Colors.cyanAccent, Colors.yellowAccent, Colors.deepPurple, Colors.orange, Colors.white]),

      // ✅ 200：7色
      200: _gradient([
        Colors.redAccent,
        Colors.orangeAccent,
        Colors.yellowAccent,
        Colors.greenAccent,
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
      ]),

      // ✅ 210：8色
      210: _gradient([
        Colors.pinkAccent,
        Colors.cyanAccent,
        Colors.greenAccent,
        Colors.yellowAccent,
        Colors.deepOrangeAccent,
        Colors.lightBlueAccent,
        Colors.indigoAccent,
        Colors.purpleAccent,
      ]),

      // ✅ 220：9色，九彩终极
      220: _gradient([
        Colors.redAccent,
        Colors.orangeAccent,
        Colors.yellowAccent,
        Colors.greenAccent,
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.indigoAccent,
        Colors.purpleAccent,
        Colors.white,
      ]),

      // ✅ 兜底超限值
      999999: _gradient([
        Colors.white,
        Colors.amber.shade200,
        Colors.black.withOpacity(0.2),
      ]),
    };

    final matched = decorations.entries.firstWhere(
          (entry) => aptitude <= entry.key,
      orElse: () => decorations.entries.last,
    );

    return matched.value;
  }

  /// 🔧 简化渐变构建
  static BoxDecoration _gradient(List<Color> colors) {
    return BoxDecoration(
      gradient: LinearGradient(colors: colors),
    );
  }
}
