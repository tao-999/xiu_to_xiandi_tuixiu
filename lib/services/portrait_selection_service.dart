import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 引入 debugPrint

class PortraitSelectionService {
  static const _keyPrefix = 'portrait_selection_';

  static Future<void> saveSelection(String discipleId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$discipleId', index);
    debugPrint('[PortraitSelectionService] 保存立绘：$discipleId => $index');
  }

  static Future<int> getSelection(String discipleId) async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('$_keyPrefix$discipleId') ?? 0;
    debugPrint('[PortraitSelectionService] 读取立绘：$discipleId => $index');
    return index;
  }
}
