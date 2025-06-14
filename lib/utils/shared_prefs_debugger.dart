// lib/services/debug/shared_prefs_debugger.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsDebugger {
  /// 输出每个 key 的字符长度 + 总长度
  static Future<void> printPrefsSizeDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final List<_PrefEntry> entries = [];

    for (final key in keys) {
      final value = prefs.get(key);
      if (value == null) continue;

      String content;
      if (value is String) {
        content = value;
      } else if (value is List<String>) {
        content = value.join(',');
      } else {
        content = json.encode(value);
      }

      entries.add(_PrefEntry(key: key, length: content.length));
    }

    entries.sort((a, b) => b.length.compareTo(a.length));

    print('📦 SharedPreferences 各项占用（按长度排序）:');
    for (final e in entries) {
      print('🔹 ${e.key} ：${e.length} 字符');
    }

    final total = entries.fold(0, (sum, e) => sum + e.length);
    print('🧠 当前 SharedPreferences 总占用：$total 字符');
    print('⚠️ 建议 < 50,000，最大不要超过 500,000 字符（约 500KB）');
  }
}

class _PrefEntry {
  final String key;
  final int length;
  _PrefEntry({required this.key, required this.length});
}
