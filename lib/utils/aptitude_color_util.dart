import 'dart:math';
import 'package:flutter/material.dart';

class AptitudeColorUtil {
  static final Map<int, Color> fixedSingleColors = {
    4: Color(0xFF81C784),   // 31–40 亮绿色
    5: Color(0xFF64B5F6),   // 41–50 鲜蓝色
    6: Color(0xFF4DB6AC),   // 51–60 青绿色（原先7）
    7: Color(0xFFBA68C8),   // 61–70 紫罗兰（原先6）
    8: Color(0xFFFFD54F),   // 71–80 鲜黄色
    9: Color(0xFFFF8A65),   // 81–90 鲜橙色
    10: Color(0xFFE57373),  // 91–100 鲜红色
  };

  static BoxDecoration getBackgroundDecoration(int aptitude) {
    final group = ((aptitude - 1) / 10).floor() + 1;

    if (group <= 3) {
      // 1–30 灰色
      return BoxDecoration(color: Colors.grey.shade300);
    } else if (group <= 10) {
      // 31–100 单色
      final color = fixedSingleColors[group] ?? Colors.grey.shade400;
      return BoxDecoration(color: color);
    } else {
      // >=101 渐变
      final colorCount = _getGradientColorCount(group);
      final colors = _generateDeterministicColors(group, colorCount);
      return _gradient(colors);
    }
  }

  static int _getGradientColorCount(int group) {
    final n = ((group - 10) / 10).floor() + 2;
    return n.clamp(2, 6);
  }

  static List<Color> _generateDeterministicColors(int group, int count) {
    final rng = Random(group + 9999);
    return List.generate(count, (_) => _randomColdColor(rng));
  }

  static Color _randomColdColor(Random rng) {
    final hue = rng.nextInt(120) + 160; // 冷色系
    final saturation = rng.nextDouble() * 0.4 + 0.3;
    final lightness = rng.nextDouble() * 0.3 + 0.4;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), saturation, lightness).toColor();
  }

  static BoxDecoration _gradient(List<Color> colors) {
    return BoxDecoration(
      gradient: LinearGradient(colors: colors),
    );
  }
}
