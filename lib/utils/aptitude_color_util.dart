// 📦 lib/utils/aptitude_color_util.dart

import 'package:flutter/material.dart';

class AptitudeColorUtil {
  /// 根据资质返回对应背景色（带骚味的版本）
  static Color getBackgroundColor(int aptitude) {
    if (aptitude <= 30) return Colors.grey.shade300;     // 凡人灰
    if (aptitude <= 40) return Colors.green.shade100;     // 绿油油
    if (aptitude <= 50) return Colors.blue.shade100;      // 蓝瘦香菇
    if (aptitude <= 60) return Colors.purple.shade100;    // 紫气东来
    return Colors.amber.shade100;                         // 金色传说
  }
}
