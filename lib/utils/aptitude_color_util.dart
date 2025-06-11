// 📦 lib/utils/aptitude_color_util.dart

import 'package:flutter/material.dart';

class AptitudeColorUtil {
  /// ✅ 不管资质高低，都只返回 BoxDecoration（纯色或渐变），UI只写一句
  static BoxDecoration getBackgroundDecoration(int aptitude) {
    final decorations = <int, BoxDecoration>{
      10: BoxDecoration(color: Colors.grey.shade300), // 凡人灰
      20: BoxDecoration(color: Colors.grey.shade300), // 凡人灰
      30: BoxDecoration(color: Colors.grey.shade300), // 凡人灰
      40: BoxDecoration(color: Colors.green.shade100), // 灵根初显
      50: BoxDecoration(color: Colors.blue.shade100), // 蓝瘦香菇
      60: BoxDecoration(color: Colors.purple.shade100), // 紫气东来
      70: BoxDecoration(color: Colors.amber.shade100), // 金色传说
      80: BoxDecoration(color: Colors.red.shade200),   // 赤焰红莲
      90: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.white]),
      ), // 神圣之体
      100: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.cyan.shade100, Colors.white, Colors.indigo.shade100]),
      ), // 混元道胎
      999999: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade200, Colors.white, Colors.black.withOpacity(0.2)]),
      ), // 虹光九转（兜底）
    };

    final matched = decorations.entries.firstWhere(
          (entry) => aptitude <= entry.key,
      orElse: () => decorations.entries.last,
    );

    return matched.value;
  }
}
